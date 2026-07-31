# Profile SELECT rollout checklist

## Scope

This checklist gates the future change that closes broad direct `SELECT` access
to `public.users`.

It does not authorize production writes or production migration execution.
Production rollout requires a separate explicit approval after local and staging
verification.

## Current prepared state

- Flutter profile read paths use `UserProfileService`.
- Public profile consumers read `public_profiles`.
- Referral-code lookup reads `private_profiles`.
- Direct `UsersTable` usage remains only in legacy profile write flows:
  registration completion and edit profile save.
- Local migration `20260725100000_add_profile_projections.sql` defines the
  projection views.
- Local pgTAP file `supabase/tests/database/profile_projections_test.sql`
  covers grants, column exposure and owner/admin row visibility.

## Required local commands

Run these against local Supabase only:

```bash
supabase db reset
supabase test db supabase/tests/database/profile_projections_test.sql --local
supabase test db supabase/tests/database/users_authorization_test.sql --local
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
git diff --check
```

Do not continue if Docker or local Supabase is unavailable.

## Required staging checks

Before any production rollout:

- verify app startup, OTP completion check, profile header, edit profile initial
  form and invite-link creation with a designated staging user;
- verify anonymous users can still read only `public_profiles`;
- verify authenticated non-admin users can read only their own
  `private_profiles` row;
- verify admin users can read private profile rows through the intended admin
  path only;
- verify registration completion and edit profile save still work through the
  existing write policy model;
- confirm logs do not contain phone numbers, device ids, referral codes, JWTs or
  raw SQL errors.

## Future migration shape

The actual revoke migration should be a separate reviewed commit after all
checks above pass. Its scope should be limited to direct `public.users` read
access, for example:

```sql
begin;

drop policy if exists "users_select_all" on public.users;
drop policy if exists "users_select_all_clean" on public.users;

revoke select on table public.users from anon, authenticated;

grant select on table public.users to service_role;
grant select on table public.public_profiles to anon, authenticated, service_role;
grant select on table public.private_profiles to authenticated, service_role;

commit;
```

The exact migration must be generated from the then-current hosted grants/RLS
diff and must not be run directly from Codex.

## Stop conditions

Do not create or apply the revoke migration if any of these are true:

- any Flutter profile read still queries `UsersTable`;
- local pgTAP is not green;
- staging does not contain the projection views;
- a generated FlutterFlow screen was regenerated and reintroduced direct profile
  reads;
- admin/private profile access has no tested staging path;
- production grants differ from local assumptions.
