begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

insert into auth.users (id)
values
  ('00000000-0000-0000-0000-00000000a100'),
  ('00000000-0000-0000-0000-00000000b200'),
  ('00000000-0000-0000-0000-00000000c300');

update public.users
set
  full_name = case
    when id = '00000000-0000-0000-0000-00000000a100' then 'Referrer'
    when id = '00000000-0000-0000-0000-00000000b200' then 'Referee'
    else 'Other user'
  end,
  status = 'approved',
  referral_code = case
    when id = '00000000-0000-0000-0000-00000000a100' then 'REF-A100'
    when id = '00000000-0000-0000-0000-00000000b200' then 'REF-B200'
    else 'REF-C300'
  end
where id in (
  '00000000-0000-0000-0000-00000000a100',
  '00000000-0000-0000-0000-00000000b200',
  '00000000-0000-0000-0000-00000000c300'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.process_referral(text, uuid, text)',
    'EXECUTE'
  ),
  'anon may not execute process_referral'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.process_referral(text, uuid, text)',
    'EXECUTE'
  ),
  'authenticated may execute process_referral'
);

set local role anon;

select throws_ok(
  $$
    select public.process_referral(
      'REF-A100',
      '00000000-0000-0000-0000-00000000b200',
      'anon-device'
    )
  $$,
  '42501',
  'permission denied for function process_referral',
  'anonymous referral mutation is denied before function body runs'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000b200',
  true
);

select is(
  public.process_referral(
    'REF-A100',
    '00000000-0000-0000-0000-00000000c300',
    'mismatch-device'
  )->>'message',
  'Referral user mismatch',
  'authenticated caller cannot apply referral to another user id'
);

reset role;

select is(
  (select referred_by_id from public.users where id = '00000000-0000-0000-0000-00000000c300'),
  null::uuid,
  'mismatched referral does not update the target profile'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000b200',
  true
);

select is(
  public.process_referral(
    'REF-A100',
    '00000000-0000-0000-0000-00000000b200',
    'device-b200'
  )->>'success',
  'true',
  'authenticated caller may apply a valid referral to themselves'
);

reset role;

select is(
  (select referred_by_id from public.users where id = '00000000-0000-0000-0000-00000000b200'),
  '00000000-0000-0000-0000-00000000a100'::uuid,
  'valid referral updates the authenticated profile'
);

select is(
  (select count(*) from public.referral_stats where referee_id = '00000000-0000-0000-0000-00000000b200'),
  1::bigint,
  'valid referral writes one referral_stats row'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-00000000b200',
  true
);

select is(
  public.process_referral(
    'REF-A100',
    '00000000-0000-0000-0000-00000000b200',
    'device-b200'
  )->>'message',
  'Referral already applied',
  'duplicate referral returns a stable public error'
);

select is(
  public.process_referral(
    'UNKNOWN',
    '00000000-0000-0000-0000-00000000b200',
    'new-device'
  )->>'message',
  'Invalid referral code',
  'invalid code returns a stable public error'
);

reset role;

select * from finish();

rollback;
