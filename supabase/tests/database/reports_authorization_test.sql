begin;

create extension if not exists pgtap with schema extensions;

select plan(8);

-- The schema-only baseline does not include hosted table ACLs. These local
-- grants are rolled back with the test transaction and let RLS be exercised.
grant select, insert on table public.reports to authenticated;
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
  '40000000-0000-0000-0000-000000000001',
  'Reported parking',
  52.1,
  21.1,
  '00000000-0000-0000-0000-0000000000b2',
  'approved'
);

insert into public.reports (
  id,
  parking_id,
  user_id,
  comment,
  status,
  report,
  created_at
)
values (
  9001,
  '40000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-0000000000b2',
  'Existing user B report',
  'approved',
  'Report1',
  now()
);

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'reports'
      and cmd = 'INSERT'
      and with_check = 'true'
  $$,
  'reports insert policies do not allow all authenticated rows'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);

select lives_ok(
  $$
    insert into public.reports (
      id,
      parking_id,
      user_id,
      comment,
      status,
      report,
      created_at
    )
    values (
      9002,
      '40000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000a1',
      'Own report',
      'approved',
      'Report2',
      now()
    )
  $$,
  'user may insert a report for themselves'
);

select is(
  (select status from public.reports where id = 9002),
  'approved',
  'explicit report status is stored unchanged'
);

select throws_ok(
  $$
    insert into public.reports (
      id,
      parking_id,
      user_id,
      comment,
      status,
      report,
      created_at
    )
    values (
      9003,
      '40000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000b2',
      'Cross-user report',
      'approved',
      'Report3',
      now()
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "reports"',
  'user may not insert a report for another user'
);

select results_eq(
  $$
    select id
    from public.reports
    order by id
  $$,
  $$ values (9002::bigint) $$,
  'user sees only their own reports'
);

reset role;
set local role anon;

select throws_ok(
  $$
    insert into public.reports (
      id,
      parking_id,
      user_id,
      comment,
      status,
      report,
      created_at
    )
    values (
      9004,
      '40000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000a1',
      'Anonymous report',
      'approved',
      'Report1',
      now()
    )
  $$,
  '42501',
  'permission denied for table reports',
  'anon may not insert reports'
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
    select id
    from public.reports
    order by id
  $$,
  $$ values (9001::bigint), (9002::bigint) $$,
  'admin may see all reports'
);

reset role;
set local role service_role;

select lives_ok(
  $$
    insert into public.reports (
      id,
      parking_id,
      user_id,
      comment,
      status,
      report,
      created_at
    )
    values (
      9005,
      '40000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000b2',
      'Service report',
      'approved',
      'Report1',
      now()
    )
  $$,
  'service_role keeps administrative reports insert access'
);

reset role;

select * from finish();

rollback;
