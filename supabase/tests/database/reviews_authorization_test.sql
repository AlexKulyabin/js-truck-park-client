begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

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
    '50000000-0000-0000-0000-000000000001',
    'Reviewed parking',
    52.1,
    21.1,
    '00000000-0000-0000-0000-0000000000b2',
    'approved'
  ),
  (
    '50000000-0000-0000-0000-000000000002',
    'Other reviewed parking',
    52.2,
    21.2,
    '00000000-0000-0000-0000-0000000000b2',
    'approved'
  );

insert into public.reviews (
  id,
  parking_id,
  user_id,
  comment,
  rating_impression,
  rating_arrival,
  rating_security,
  rating_infrastructure,
  rating_comfort,
  created_at
)
values
  (
    9101,
    '50000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000a1',
    'Existing user A review',
    5,
    4,
    3,
    2,
    1,
    now()
  ),
  (
    9102,
    '50000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000b2',
    'Existing user B review',
    1,
    2,
    3,
    4,
    5,
    now()
  );

select is_empty(
  $$
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'reviews'
      and cmd in ('INSERT', 'UPDATE', 'DELETE')
      and (
        with_check = 'true'
        or qual = 'true'
      )
  $$,
  'review mutation policies do not allow all authenticated rows'
);

select ok(
  has_table_privilege('authenticated', 'public.reviews', 'INSERT'),
  'authenticated may insert reviews'
);

select ok(
  has_column_privilege('authenticated', 'public.reviews', 'comment', 'UPDATE'),
  'authenticated may update review comments'
);

select ok(
  has_column_privilege(
    'authenticated',
    'public.reviews',
    'rating_impression',
    'UPDATE'
  ),
  'authenticated may update review ratings'
);

select ok(
  not has_column_privilege('authenticated', 'public.reviews', 'average_score', 'UPDATE'),
  'authenticated may not update calculated average score'
);

select ok(
  not has_column_privilege('authenticated', 'public.reviews', 'user_id', 'UPDATE'),
  'authenticated may not transfer review ownership'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-0000000000a1',
  true
);

select lives_ok(
  $$
    insert into public.reviews (
      id,
      parking_id,
      user_id,
      comment,
      rating_impression,
      rating_arrival,
      rating_security,
      rating_infrastructure,
      rating_comfort,
      created_at
    )
    values (
      9103,
      '50000000-0000-0000-0000-000000000002',
      '00000000-0000-0000-0000-0000000000a1',
      'Own new review',
      5,
      5,
      4,
      4,
      3,
      now()
    )
  $$,
  'user may insert their own review'
);

select throws_ok(
  $$
    insert into public.reviews (
      id,
      parking_id,
      user_id,
      comment,
      rating_impression,
      rating_arrival,
      rating_security,
      rating_infrastructure,
      rating_comfort,
      created_at
    )
    values (
      9104,
      '50000000-0000-0000-0000-000000000002',
      '00000000-0000-0000-0000-0000000000b2',
      'Cross-user review',
      5,
      5,
      5,
      5,
      5,
      now()
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "reviews"',
  'user may not insert a review for another user'
);

select lives_ok(
  $$
    update public.reviews
    set
      comment = 'Updated owner review',
      rating_arrival = 5
    where id = 9101
  $$,
  'user may update mutable fields on their own review'
);

select is_empty(
  $$
    update public.reviews
    set comment = 'Cross-user update'
    where id = 9102
    returning id
  $$,
  'RLS prevents updating another user review'
);

select throws_ok(
  $$
    update public.reviews
    set average_score = 5
    where id = 9101
  $$,
  '42501',
  'permission denied for table reviews',
  'user may not update calculated average score'
);

select throws_ok(
  $$
    update public.reviews
    set user_id = '00000000-0000-0000-0000-0000000000b2'
    where id = 9101
  $$,
  '42501',
  'permission denied for table reviews',
  'user may not transfer review ownership'
);

select is_empty(
  $$
    delete from public.reviews
    where id = 9102
    returning id
  $$,
  'user may not delete another user review'
);

select results_eq(
  $$
    delete from public.reviews
    where id = 9101
    returning id
  $$,
  $$ values (9101::bigint) $$,
  'user may delete their own review'
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
    delete from public.reviews
    where id = 9102
    returning id
  $$,
  $$ values (9102::bigint) $$,
  'admin may delete another user review'
);

reset role;
set local role service_role;

select lives_ok(
  $$
    update public.reviews
    set average_score = 4.5
    where id = 9103
  $$,
  'service_role keeps administrative review update access'
);

reset role;

select * from finish();

rollback;
