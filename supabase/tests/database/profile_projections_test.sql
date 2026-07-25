begin;

create extension if not exists pgtap with schema extensions;

select plan(15);

insert into auth.users (id)
values
  ('00000000-0000-0000-0000-00000000d100'),
  ('00000000-0000-0000-0000-00000000e200');

update public.users
set
  full_name = case
    when id = '00000000-0000-0000-0000-00000000d100' then 'Owner User'
    else 'Other User'
  end,
  avatar_url = case
    when id = '00000000-0000-0000-0000-00000000d100'
      then 'https://example.test/owner.png'
    else 'https://example.test/other.png'
  end,
  phone = case
    when id = '00000000-0000-0000-0000-00000000d100' then '+11111111111'
    else '+22222222222'
  end,
  is_premium = false,
  referral_code = case
    when id = '00000000-0000-0000-0000-00000000d100' then 'REF-D100'
    else 'REF-E200'
  end,
  status = 'approved',
  is_admin = false,
  last_device_id = case
    when id = '00000000-0000-0000-0000-00000000d100' then 'device-d100'
    else 'device-e200'
  end
where id in (
  '00000000-0000-0000-0000-00000000d100',
  '00000000-0000-0000-0000-00000000e200'
);

select ok(
  has_table_privilege('anon', 'public.public_profiles', 'SELECT'),
  'anon may read public profiles'
);
select ok(
  has_table_privilege('authenticated', 'public.public_profiles', 'SELECT'),
  'authenticated may read public profiles'
);
select ok(
  not has_table_privilege('anon', 'public.private_profiles', 'SELECT'),
  'anon may not read private profiles'
);
select ok(
  has_table_privilege('authenticated', 'public.private_profiles', 'SELECT'),
  'authenticated may read private profiles'
);

select is(
  (
    select string_agg(column_name, ',' order by ordinal_position)
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'public_profiles'
  ),
  'id,full_name,avatar_url',
  'public_profiles exposes only public profile columns'
);

select ok(
  not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'public_profiles'
      and column_name in (
        'phone',
        'is_premium',
        'referral_code',
        'theme',
        'status',
        'is_admin',
        'referred_by_id',
        'last_device_id'
      )
  ),
  'public_profiles omits sensitive profile columns'
);

select is(
  (
    select string_agg(column_name, ',' order by ordinal_position)
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'private_profiles'
  ),
  'id,full_name,avatar_url,phone,is_premium,referral_code,theme,updated_at,status,is_admin,referred_by_id,last_device_id',
  'private_profiles exposes the owner/admin profile shape'
);

set local role anon;

select is(
  (select count(*) from public.public_profiles),
  2::bigint,
  'anon can list public profile rows'
);

select throws_ok(
  $$ select count(*) from public.private_profiles $$,
  '42501',
  'permission denied for view private_profiles',
  'anon cannot query private profile rows'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000d100',
  true
);

select is(
  (select count(*) from public.private_profiles),
  1::bigint,
  'non-admin user sees only their private profile row'
);

select is(
  (select phone from public.private_profiles),
  '+11111111111',
  'owner can read their own private phone'
);

select is_empty(
  $$ select id from public.private_profiles where id = '00000000-0000-0000-0000-00000000e200' $$,
  'non-admin user cannot read another private profile row'
);

reset role;

update public.users
set is_admin = true
where id = '00000000-0000-0000-0000-00000000d100';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000d100',
  true
);

select is(
  (select count(*) from public.private_profiles),
  2::bigint,
  'admin user can read private profile rows'
);

select is(
  (
    select referral_code
    from public.private_profiles
    where id = '00000000-0000-0000-0000-00000000e200'
  ),
  'REF-E200',
  'admin user can read another private referral code'
);

reset role;

select ok(
  has_table_privilege('service_role', 'public.private_profiles', 'SELECT'),
  'service_role may read private profiles'
);

select * from finish();

rollback;
