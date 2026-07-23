begin;

create extension if not exists pgtap with schema extensions;

select plan(20);

-- Stable test identities; no production data is used.
insert into auth.users (id)
values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b2');

select is(
  (select count(*) from public.users where id in (
    '00000000-0000-0000-0000-0000000000a1',
    '00000000-0000-0000-0000-0000000000b2'
  )),
  2::bigint,
  'Auth signup trigger creates both public profiles'
);

update public.users
set
  full_name = case
    when id = '00000000-0000-0000-0000-0000000000a1' then 'User A'
    else 'User B'
  end,
  avatar_url = case
    when id = '00000000-0000-0000-0000-0000000000a1'
      then 'https://example.test/a.png'
    else 'https://example.test/b.png'
  end,
  status = 'approved',
  is_admin = false,
  is_premium = false,
  referral_code = case
    when id = '00000000-0000-0000-0000-0000000000a1' then 'REF-A'
    else 'REF-B'
  end,
  referred_by_id = null,
  last_device_id = case
    when id = '00000000-0000-0000-0000-0000000000a1' then 'device-a'
    else 'device-b'
  end
where id in (
  '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000b2'
);

select ok(
  not has_table_privilege('authenticated', 'public.users', 'UPDATE'),
  'authenticated has no table-level UPDATE grant'
);
select ok(
  not has_table_privilege('anon', 'public.users', 'UPDATE'),
  'anon has no table-level UPDATE grant'
);
select ok(
  has_table_privilege('service_role', 'public.users', 'UPDATE'),
  'service_role keeps table-level UPDATE grant'
);

select ok(
  has_column_privilege('authenticated', 'public.users', 'full_name', 'UPDATE'),
  'authenticated may update full_name'
);
select ok(
  has_column_privilege('authenticated', 'public.users', 'avatar_url', 'UPDATE'),
  'authenticated may update avatar_url'
);
select ok(
  has_column_privilege('authenticated', 'public.users', 'updated_at', 'UPDATE'),
  'authenticated may update updated_at'
);
select ok(
  has_column_privilege('authenticated', 'public.users', 'last_device_id', 'UPDATE'),
  'authenticated may update last_device_id'
);

select ok(
  not has_column_privilege('authenticated', 'public.users', 'is_admin', 'UPDATE'),
  'authenticated may not update is_admin'
);
select ok(
  not has_column_privilege('authenticated', 'public.users', 'is_premium', 'UPDATE'),
  'authenticated may not update is_premium'
);
select ok(
  not has_column_privilege('authenticated', 'public.users', 'status', 'UPDATE'),
  'authenticated may not update status'
);
select ok(
  not has_column_privilege('authenticated', 'public.users', 'referral_code', 'UPDATE'),
  'authenticated may not update referral_code'
);
select ok(
  not has_column_privilege('authenticated', 'public.users', 'referred_by_id', 'UPDATE'),
  'authenticated may not update referred_by_id'
);
select ok(
  not has_column_privilege('authenticated', 'public.users', 'phone', 'UPDATE'),
  'authenticated may not update phone'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);

select lives_ok(
  $$
    update public.users
    set
      full_name = 'User A updated',
      avatar_url = 'https://example.test/a-updated.png',
      updated_at = now(),
      last_device_id = 'device-a-updated'
    where id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  'user may update their own allowed profile fields'
);

select throws_ok(
  $$
    update public.users
    set is_admin = true
    where id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'permission denied for table users',
  'user may not promote themselves to admin'
);

select throws_ok(
  $$
    update public.users
    set
      is_premium = true,
      status = 'rejected',
      referral_code = 'COMPROMISED',
      referred_by_id = '00000000-0000-0000-0000-0000000000b2',
      phone = '+10000000000'
    where id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'permission denied for table users',
  'user may not update premium, moderation, referral, or phone fields'
);

select is_empty(
  $$
    update public.users
    set full_name = 'Compromised'
    where id = '00000000-0000-0000-0000-0000000000b2'
    returning id
  $$,
  'RLS prevents updating another user row'
);

reset role;
set local role anon;

select throws_ok(
  $$
    update public.users
    set full_name = 'Anonymous update'
    where id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  '42501',
  'permission denied for table users',
  'anon may not update a profile'
);

reset role;

set local role service_role;

select lives_ok(
  $$
    update public.users
    set is_premium = true
    where id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  'service_role keeps administrative update access'
);

reset role;

select * from finish();

rollback;
