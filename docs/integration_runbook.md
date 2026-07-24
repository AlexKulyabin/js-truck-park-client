# Production-parallel integration runbook

## Purpose

The integration build validates the existing Flutter client against the current
Supabase project without changing database contracts or intentionally writing
production data.

It is an accident-prevention mode, not a security boundary. Supabase RLS remains
the only server-side authorization boundary.

## Build modes

| Build | Environment default | Application identity | External SDKs | Navigation |
|---|---|---|---|---|
| Debug/Profile | `integration` | `com.mycompany.jstrackpark.dev`; `JS Truck Park Dev` | RevenueCat and Chottu Link disabled | read-only allowlist |
| Release | `production` | `com.mycompany.jstrackpark`; `JS Truck Park` | unchanged | unchanged |

The integration UI displays both the Flutter debug banner and a `READ ONLY`
banner.

## Allowed integration writes

Integration remains read-only by navigation and by default. Any intentionally
enabled write must be listed in `AppWriteOperation` and checked through
`AppConfig.canPerformWrite(...)` before the UI starts the action.

Currently allowed:

- `favoriteToggle`: insert/delete the current user's favorite parking row.
- `reportCreate`: insert the current user's report row for a parking, using the
  existing Flutter payload contract.

Reserved but disabled in every build:

- `profileUpdate`: the typed client contract exists, but it has no gateway/UI
  wiring and cannot be enabled before the profile/avatar prerequisites in
  `profile_update_contract.md` are complete.

Test-write pilot:

- `reviewCreate` stays disabled by default. It can be enabled only in a
  Debug/Profile integration build with
  `--dart-define=APP_ENABLE_TEST_WRITES=true` and a non-production
  `SUPABASE_URL`. Startup fails if this flag is used in Release or with the
  production Supabase host.
- The same guarded test-write flag also enables `reviewUpdate`,
  `reviewDelete` and `reviewPhotoManage` capabilities for staged review
  management work. UI wiring is still staged separately per operation.

## Allowed integration routes

- `/`, `/splash`;
- `/onboard1`, `/onboard2`, `/onboard3`;
- `/enterPhoneNumber`, `/validateSmsCode`;
- `/homePage`;
- `/language`.

All other routes redirect to Home for an authenticated test user or to phone
authentication for a signed-out user. In particular, registration, profile
editing, account deletion, parking/review/report creation, referrals, requests
and subscription screens are unavailable.

## Configuration

Defaults preserve the current Supabase project. Publishable client values may be
overridden at build time:

```bash
flutter run \
  --dart-define=APP_ENV=integration \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REDACTED
```

For local/staging review-write testing only:

```bash
flutter run \
  --dart-define=APP_ENV=integration \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REDACTED \
  --dart-define=APP_ENABLE_TEST_WRITES=true
```

Supported `APP_ENV` values are `integration` and `production`. Never pass a
database password, secret key or service-role key to Flutter. Dart defines are
compiled into the application and are suitable only for publishable values.

For safety, `integration` is accepted only by Debug/Profile builds and
`production` only by Release builds. A mismatched override fails during app
startup instead of enabling production side effects under the wrong native app
identity.

## Safe smoke sequence

1. Install the debug build alongside the production app.
2. Confirm the app label is `JS Truck Park Dev` and the `READ ONLY` banner is
   visible.
3. Complete local onboarding; this only updates the dev app's local storage.
4. Sign in only with the designated production test user.
5. Confirm Home loads parking markers using `get_filtered_parkings`.
6. Exercise viewport, search and filters.
7. Open one parking details component from Home and toggle the favorite button;
   confirm the UI rolls back if the backend rejects the write.
8. From the same parking details component, create only a test report using the
   designated production test user; confirm the UI stays open and shows an
   error if the backend rejects the write.
9. Confirm Language can switch between `en` and `ru`.
10. Confirm RevenueCat and production deep links do not initialize.
11. Do not create a missing profile; registration is intentionally blocked.
12. Sign out by clearing the dev app or through a future integration-only safe
    control; do not use account deletion.

## Verification commands

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build ios --simulator
```

## Rollback

Revert the integration commit if production release configuration changes,
debug and production identifiers collide, a blocked route becomes reachable,
RevenueCat/deep links start in integration mode, or any connectivity diagnostic
performs a write.

This mode must not be used as a substitute for a staging project, RLS tests or a
version-controlled Supabase schema.
