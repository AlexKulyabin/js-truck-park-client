begin;

create extension if not exists pgtap with schema extensions;

select plan(11);

-- The schema-only baseline does not include hosted table ACLs. These local,
-- rolled-back grants let the test exercise RLS and the migration grants.
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
values
  (
    '10000000-0000-0000-0000-0000000000a1',
    'Owner parking',
    52.1,
    21.1,
    '00000000-0000-0000-0000-0000000000a1',
    'pending'
  ),
  (
    '10000000-0000-0000-0000-0000000000b2',
    'Other parking',
    52.2,
    21.2,
    '00000000-0000-0000-0000-0000000000b2',
    'pending'
  );

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'parkings'
      and policyname = 'Allow authenticated users to update parkings'
  $$,
  'broad authenticated parking update policy is removed'
);

select ok(
  has_column_privilege('authenticated', 'public.parkings', 'address', 'UPDATE'),
  'authenticated may update owner-maintained parking fields'
);

select ok(
  not has_column_privilege('authenticated', 'public.parkings', 'status', 'UPDATE'),
  'authenticated may not update parking moderation status'
);

select ok(
  not has_column_privilege('authenticated', 'public.parkings', 'created_by', 'UPDATE'),
  'authenticated may not transfer parking ownership'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);

select lives_ok(
  $$
    update public.parkings
    set address = 'Owner parking updated'
    where id = '10000000-0000-0000-0000-0000000000a1'
  $$,
  'owner may update allowed parking fields'
);

select is_empty(
  $$
    update public.parkings
    set address = 'Cross-user update'
    where id = '10000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'RLS prevents updating another user parking'
);

select throws_ok(
  $$
    update public.parkings
    set status = 'approved'
    where id = '10000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'permission denied for table parkings',
  'owner may not approve their own parking'
);

select throws_ok(
  $$
    update public.parkings
    set created_by = '00000000-0000-0000-0000-0000000000b2'
    where id = '10000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'permission denied for table parkings',
  'owner may not transfer parking ownership'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000ad00',
  true
);

select lives_ok(
  $$
    update public.parkings
    set address = 'Admin edited address'
    where id = '10000000-0000-0000-0000-0000000000b2'
  $$,
  'admin may update allowed parking fields for moderation workflows'
);

select throws_ok(
  $$
    update public.parkings
    set status = 'approved'
    where id = '10000000-0000-0000-0000-0000000000b2'
  $$,
  '42501',
  'permission denied for table parkings',
  'admin moderation status updates are not exposed to direct client grants'
);

reset role;
set local role service_role;

select lives_ok(
  $$
    update public.parkings
    set status = 'approved'
    where id = '10000000-0000-0000-0000-0000000000b2'
  $$,
  'service_role keeps administrative parking update access'
);

reset role;

select * from finish();

rollback;
