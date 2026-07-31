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

## Allowed integration routes

- `/`, `/splash`;
- `/onboard1`, `/onboard2`, `/onboard3`;
- `/enterPhoneNumber`, `/validateSmsCode`;
- `/homePage`;
- `/profile` (read-only shell; account deletion is blocked);
- `/payWall` (preview only; RevenueCat restore and purchase are blocked);
- `/requests`, `/moderationParking`, `/acceptedParking`, `/rejectedParking`;
- `/reviewsAndComplaints`, `/favourites`;
- `/photoDetailed`, `/photoDetailedReviews`;
- `/language`.

All other routes redirect to Home for an authenticated test user or to phone
authentication for a signed-out user. Registration, profile editing, account
deletion, parking creation, referrals and subscription purchases are
unavailable. Favorite toggles and report creation are enabled through explicit
capabilities. Review create/update/delete/photo writes require a debug/profile
build connected to a non-production Supabase project with
`APP_ENABLE_TEST_WRITES=true`. Production Release builds separately allow a
user to create one review with optional photos; review update and delete remain
disabled after publication. See `docs/user_write_closed_test_activation.md`.

## Configuration

Defaults preserve the current Supabase project. Publishable client values may be
overridden at build time:

```bash
flutter run \
  --dart-define=APP_ENV=integration \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REDACTED
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
7. Open one parking details panel, switch tabs and toggle the favorite button;
   confirm the panel stays visible and rolls back if the backend rejects the
   write.
8. Create only a test report with the designated test user and confirm an error
   leaves the parking panel open.
9. Confirm Language can switch between `en` and `ru`.
10. Confirm RevenueCat and production deep links do not initialize.
11. Open Profile and confirm its read-only information is visible while
   write-capable child screens return to Home and account deletion cannot run.
12. Open Subscription, Requests, Reviews and Favourites. Confirm their read-only
    content loads and subscription actions do not start a store purchase.
13. Open a request detail and a favourite parking, then return to Profile.
14. Do not create a missing profile; registration is intentionally blocked.
15. Sign out through Profile when needed; do not use account deletion.

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
