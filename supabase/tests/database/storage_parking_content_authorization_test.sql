begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'parking_content',
  'parking_content',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into auth.users (id)
values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b2');

update public.users
set
  full_name = case
    when id = '00000000-0000-0000-0000-0000000000a1' then 'User A'
    else 'User B'
  end,
  status = 'approved',
  is_admin = false
where id in (
  '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000b2'
);

insert into public.parkings (id, address, latitude, longitude, created_by, status)
values
  (
    '20000000-0000-0000-0000-0000000000a1',
    'User A parking',
    52.1,
    21.1,
    '00000000-0000-0000-0000-0000000000a1',
    'pending'
  ),
  (
    '20000000-0000-0000-0000-0000000000b2',
    'User B parking',
    52.2,
    21.2,
    '00000000-0000-0000-0000-0000000000b2',
    'pending'
  );

insert into public.reviews (
  id,
  user_id,
  parking_id,
  comment,
  rating_impression,
  rating_arrival,
  rating_security,
  rating_infrastructure,
  rating_comfort
)
values
  (
    5101,
    '00000000-0000-0000-0000-0000000000a1',
    '20000000-0000-0000-0000-0000000000b2',
    'A review for B parking',
    5,
    5,
    5,
    5,
    5
  ),
  (
    5102,
    '00000000-0000-0000-0000-0000000000b2',
    '20000000-0000-0000-0000-0000000000a1',
    'B review for A parking',
    5,
    5,
    5,
    5,
    5
  );

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
      and policyname not in (
        'parking_content_select_own',
        'parking_content_insert_own',
        'parking_content_update_own',
        'parking_content_delete_own'
      )
      and (
        coalesce(qual, '') like '%parking_content%'
        or coalesce(with_check, '') like '%parking_content%'
        or coalesce(qual, '') like '%parking-images%'
        or coalesce(with_check, '') like '%parking-images%'
      )
  $$,
  'legacy parking_content and stale parking-images mutation policies are removed'
);

select set_eq(
  $$
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname like 'parking_content_%_own'
  $$,
  $$ values
    ('parking_content_select_own'),
    ('parking_content_insert_own'),
    ('parking_content_update_own'),
    ('parking_content_delete_own')
  $$,
  'parking content mutation policies are owner-scoped'
);

select ok(
  (
    select prosecdef
    from pg_proc
    where oid = 'private.can_manage_parking_content(text)'::regprocedure
  ),
  'parking content ownership helper is security definer'
);

select is(
  (
    select array_to_string(proconfig, ',')
    from pg_proc
    where oid = 'private.can_manage_parking_content(text)'::regprocedure
  ),
  'search_path=""',
  'parking content ownership helper has an empty search path'
);

select ok(
  not has_function_privilege(
    'anon',
    'private.can_manage_parking_content(text)',
    'EXECUTE'
  ),
  'anon may not execute parking content ownership helper'
);

select ok(
  has_function_privilege(
    'authenticated',
    'private.can_manage_parking_content(text)',
    'EXECUTE'
  ),
  'authenticated may execute parking content ownership helper'
);

insert into storage.objects (id, bucket_id, name, owner, metadata)
values
  (
    '41000000-0000-0000-0000-0000000000b2',
    'parking_content',
    'parkings/20000000-0000-0000-0000-0000000000b2/0/photo.png',
    '00000000-0000-0000-0000-0000000000b2',
    '{"mimetype":"image/png"}'::jsonb
  ),
  (
    '41000000-0000-0000-0000-000000005102',
    'parking_content',
    'parkings/20000000-0000-0000-0000-0000000000a1/reviews/5102/0/photo.png',
    '00000000-0000-0000-0000-0000000000b2',
    '{"mimetype":"image/png"}'::jsonb
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);
select set_config('storage.allow_delete_query', 'true', true);

select lives_ok(
  $$
    insert into storage.objects (id, bucket_id, name, owner, metadata)
    values (
      '41000000-0000-0000-0000-0000000000a1',
      'parking_content',
      'parkings/20000000-0000-0000-0000-0000000000a1/0/photo.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  'parking owner may insert direct parking content'
);

select throws_ok(
  $$
    insert into storage.objects (id, bucket_id, name, owner, metadata)
    values (
      '41000000-0000-0000-0000-0000000000c3',
      'parking_content',
      'parkings/20000000-0000-0000-0000-0000000000b2/0/cross.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'user may not insert direct content for another user parking'
);

select lives_ok(
  $$
    insert into storage.objects (id, bucket_id, name, owner, metadata)
    values (
      '41000000-0000-0000-0000-000000005101',
      'parking_content',
      'parkings/20000000-0000-0000-0000-0000000000b2/reviews/5101/0/photo.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  'review author may insert review parking content'
);

select throws_ok(
  $$
    insert into storage.objects (id, bucket_id, name, owner, metadata)
    values (
      '41000000-0000-0000-0000-000000005103',
      'parking_content',
      'parkings/20000000-0000-0000-0000-0000000000a1/reviews/5102/0/cross.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'user may not insert content for another user review'
);

select lives_ok(
  $$
    update storage.objects
    set metadata = '{"mimetype":"image/webp"}'::jsonb
    where id = '41000000-0000-0000-0000-0000000000a1'
  $$,
  'parking owner may update direct parking content'
);

select throws_ok(
  $$
    update storage.objects
    set name = 'parkings/20000000-0000-0000-0000-0000000000b2/0/moved.png'
    where id = '41000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'user may not move parking content into another user parking'
);

select is_empty(
  $$
    update storage.objects
    set metadata = '{"mimetype":"image/webp"}'::jsonb
    where id = '41000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'user may not update another user parking content'
);

select results_eq(
  $$
    delete from storage.objects
    where id = '41000000-0000-0000-0000-000000005101'
    returning id
  $$,
  $$ values ('41000000-0000-0000-0000-000000005101'::uuid) $$,
  'review author may delete review parking content'
);

select results_eq(
  $$
    delete from storage.objects
    where id = '41000000-0000-0000-0000-0000000000a1'
    returning id
  $$,
  $$ values ('41000000-0000-0000-0000-0000000000a1'::uuid) $$,
  'parking owner may delete direct parking content'
);

select is_empty(
  $$
    delete from storage.objects
    where id = '41000000-0000-0000-0000-000000005102'
    returning id
  $$,
  'user may not delete another user review content'
);

reset role;

select * from finish();

rollback;
