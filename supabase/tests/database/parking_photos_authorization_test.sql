begin;

create extension if not exists pgtap with schema extensions;

select plan(9);

-- The schema-only baseline does not include hosted table ACLs. These local
-- grants are rolled back with the test transaction and let RLS be exercised.
grant select, insert, delete on table public.parking_photos to authenticated;
grant select on table public.parkings to authenticated;

insert into auth.users (id)
values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0000-00000000ad00');

update public.users
set
  full_name = case
    when id = '00000000-0000-0000-0000-00000000ad00' then 'Admin'
    when id = '00000000-0000-0000-0000-0000000000a1' then 'User A'
    else 'User B'
  end,
  status = 'approved',
  is_admin = (id = '00000000-0000-0000-0000-00000000ad00')
where id in (
  '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000b2',
  '00000000-0000-0000-0000-00000000ad00'
);

insert into public.parkings (id, address, latitude, longitude, created_by, status)
values (
  '20000000-0000-0000-0000-000000000001',
  'Approved parking',
  52.1,
  21.1,
  '00000000-0000-0000-0000-0000000000a1',
  'approved'
);

insert into public.parking_photos (id, url, parking_id, user_id)
values (
  '30000000-0000-0000-0000-0000000000b2',
  'https://example.test/b-photo.jpg',
  '20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-0000000000b2'
);

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'parking_photos'
      and policyname in (
        'Authenticated can create parking photos',
        'Authenticated can delete parking photos'
      )
  $$,
  'broad parking photo mutation policies are removed'
);

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'parking_photos'
      and cmd in ('INSERT', 'DELETE')
      and (
        with_check = 'true'
        or qual = 'true'
      )
  $$,
  'parking photo insert/delete policies do not allow all authenticated rows'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);

select lives_ok(
  $$
    insert into public.parking_photos (id, url, parking_id, user_id)
    values (
      '30000000-0000-0000-0000-0000000000a1',
      'https://example.test/a-photo.jpg',
      '20000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000a1'
    )
  $$,
  'user may insert their own parking photo row'
);

select throws_ok(
  $$
    insert into public.parking_photos (id, url, parking_id, user_id)
    values (
      '30000000-0000-0000-0000-0000000000c3',
      'https://example.test/cross-photo.jpg',
      '20000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000b2'
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "parking_photos"',
  'user may not insert a parking photo row for another user'
);

select is_empty(
  $$
    delete from public.parking_photos
    where id = '30000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'user may not delete another user photo row'
);

select results_eq(
  $$
    delete from public.parking_photos
    where id = '30000000-0000-0000-0000-0000000000a1'
    returning id
  $$,
  $$ values ('30000000-0000-0000-0000-0000000000a1'::uuid) $$,
  'user may delete their own parking photo row'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000ad00',
  true
);

select results_eq(
  $$
    delete from public.parking_photos
    where id = '30000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  $$ values ('30000000-0000-0000-0000-0000000000b2'::uuid) $$,
  'admin may delete another user photo row'
);

reset role;

select ok(
  has_table_privilege('service_role', 'public.parking_photos', 'INSERT'),
  'service_role keeps parking photo insert access'
);

select ok(
  has_table_privilege('service_role', 'public.parking_photos', 'DELETE'),
  'service_role keeps parking photo delete access'
);

select * from finish();

rollback;
