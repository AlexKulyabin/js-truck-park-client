# Profile security activation checklist

## Scope

This checklist gates any future change that enables profile or avatar writes
through the new `UserProfileService` update boundary.

It does not authorize production writes. Production rollout requires a separate
explicit decision after staging verification.

## Existing local policy tests

These test files are the minimum local gate before wiring or enabling
`AppWriteOperation.profileUpdate`:

- `supabase/tests/database/users_authorization_test.sql`
- `supabase/tests/database/storage_avatars_authorization_test.sql`

They cover:

- authenticated users may update only their own allowed profile columns:
  `full_name`, `avatar_url`, `updated_at`, `last_device_id`;
- authenticated users may not update `is_admin`, `is_premium`, `status`,
  `referral_code`, `referred_by_id` or `phone`;
- authenticated users may not update another user's profile row;
- anonymous users may not update profile rows;
- `service_role` keeps administrative update access;
- legacy bucket-only avatar mutation policies are removed;
- authenticated users may insert/update/delete only avatar objects under
  `avatars/users/<auth.uid()>/...`;
- cross-user avatar insert/update/delete fails.

## Required local commands

Run these against local Supabase only:

```bash
supabase db reset
supabase test db supabase/tests/database/users_authorization_test.sql --local
supabase test db supabase/tests/database/storage_avatars_authorization_test.sql --local
supabase db diff --local --schema public
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
git diff --check
```

`supabase db diff --local --schema public` must be empty after reset and tests.
If Docker or local Supabase is unavailable, do not enable profile writes.

## Required staging checks

Before production rollout:

- run a read-only diff of hosted `users` grants/RLS against the local
  migrations;
- run a read-only diff of hosted `avatars` Storage policies against
  `20260724103000_restrict_avatar_storage_policies.sql`;
- verify the edit profile flow with a designated staging/test user;
- verify avatar replacement, profile row update and retry behavior;
- verify cross-user avatar paths and private profile columns remain denied;
- confirm logs do not contain JWTs, phone numbers, device ids or raw SQL errors.

## Stop conditions

Do not wire the UI or enable `profileUpdate` if any of these are true:

- profile row update and avatar object handling are still separate
  client-owned operations;
- a failed avatar operation can leave an orphaned object without compensation;
- hosted policy diff shows an extra permissive production-only Storage policy;
- local pgTAP is not green;
- staging uses a real user instead of a designated test account;
- registration avatar writes are not accounted for in the same owner-path
  policy model.

## Commit boundaries

Use separate commits for:

1. backend contract/migration and policy tests;
2. gateway implementation;
3. UI wiring;
4. enabling `AppWriteOperation.profileUpdate`.

Do not combine these with unrelated profile UI cleanup or public/private
profile projection work.
