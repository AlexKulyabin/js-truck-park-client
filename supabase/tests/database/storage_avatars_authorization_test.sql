begin;

create extension if not exists pgtap with schema extensions;

select plan(9);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in ('Avatar_Upload', 'Avatar_Update', 'Avatar_Delete')
  $$,
  'legacy bucket-only avatar mutation policies are removed'
);

select set_eq(
  $$
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname like 'avatars_%_own'
  $$,
  $$ values
    ('avatars_insert_own'),
    ('avatars_update_own'),
    ('avatars_delete_own')
  $$,
  'avatar mutation policies are owner-scoped'
);

insert into storage.objects (id, bucket_id, name, owner, metadata)
values (
  '40000000-0000-0000-0000-0000000000b2',
  'avatars',
  'users/00000000-0000-0000-0000-0000000000b2/photo.png',
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
      '40000000-0000-0000-0000-0000000000a1',
      'avatars',
      'users/00000000-0000-0000-0000-0000000000a1/photo.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  'user may insert an avatar under their own path'
);

select throws_ok(
  $$
    insert into storage.objects (id, bucket_id, name, owner, metadata)
    values (
      '40000000-0000-0000-0000-0000000000c3',
      'avatars',
      'users/00000000-0000-0000-0000-0000000000b2/cross.png',
      '00000000-0000-0000-0000-0000000000a1',
      '{"mimetype":"image/png"}'::jsonb
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'user may not insert an avatar under another user path'
);

select lives_ok(
  $$
    update storage.objects
    set metadata = '{"mimetype":"image/webp"}'::jsonb
    where id = '40000000-0000-0000-0000-0000000000a1'
  $$,
  'user may update an avatar under their own path'
);

select throws_ok(
  $$
    update storage.objects
    set name = 'users/00000000-0000-0000-0000-0000000000b2/moved.png'
    where id = '40000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'user may not move their avatar into another user path'
);

select is_empty(
  $$
    update storage.objects
    set metadata = '{"mimetype":"image/webp"}'::jsonb
    where id = '40000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'user may not update another user avatar'
);

select results_eq(
  $$
    delete from storage.objects
    where id = '40000000-0000-0000-0000-0000000000a1'
    returning id
  $$,
  $$ values ('40000000-0000-0000-0000-0000000000a1'::uuid) $$,
  'user may delete an avatar under their own path'
);

select is_empty(
  $$
    delete from storage.objects
    where id = '40000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'user may not delete another user avatar'
);

reset role;

select * from finish();

rollback;
