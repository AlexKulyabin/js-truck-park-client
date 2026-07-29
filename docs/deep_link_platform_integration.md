# Deep-link platform integration

Date: 2026-07-29

Status: implemented locally for the next closed-test build. No Supabase schema,
policies, data or production write operations were changed.

## Scope

This stage makes Android and iOS link delivery deterministic while preserving
the existing public URLs and Flutter routes.

In scope:

- Chottu referral links on `https://js-truck-park.chottu.link/...`;
- existing Hosting relay links on
  `https://js-truck-park.web.app/deeplink.html?...`;
- the legacy `jstrackpark://js-truck-park.web.app/...` handoff;
- iOS Associated Domains for the Chottu domain;
- cold-start and warm-start routing through the existing `go_router` routes.

Out of scope:

- changing generated or already shared URLs;
- Firebase Hosting deployment;
- referral eligibility, Supabase RPC or RevenueCat behavior;
- reviews, parking writes or production data;
- Android/iOS build-number changes.

## Ownership contract

Each inbound URL family has one application-level owner:

| URL | Owner | Result |
|---|---|---|
| `https://js-truck-park.chottu.link/...` | ChottuLink SDK | resolve referral/deferred metadata and persist `ref` |
| `jstrackpark://js-truck-park.web.app/...` | `IncomingAppLinkCoordinator` via `app_links` | open an allowlisted Flutter route |
| direct Hosting relay URL delivered to the app | `IncomingAppLinkCoordinator` | infer the same legacy Flutter route |
| foreign domain or unknown route | none | ignore safely |

Flutter's built-in deep-link handler is disabled for release. This prevents it
from navigating to a Chottu short-link path before the ChottuLink SDK resolves
the destination. The existing `app_links` dependency now owns the legacy
custom-scheme handoff.

The coordinator allowlists only:

- `/homePage`: `targetParkingId`, `targetLat`, `targetLng`;
- `/sharedPhotoView`: `photoUrl`, `address`, `date`;
- `/splash`: `ref`.

Unknown query parameters are not forwarded into application navigation.

## Platform configuration

Android release:

- package: `com.mycompany.jstrackpark`;
- minimum API: 24, matching the currently distributed Play bundle and the
  pinned `geolocator_android` manifest requirement;
- Chottu App Link host: `js-truck-park.chottu.link`;
- Flutter built-in handler: disabled;
- Play App Signing SHA-256 remains configured in the Chottu dashboard.

iOS release:

- bundle ID: `com.mycompany.jstrackpark`;
- Apple Team ID: `8XNBY3768H`;
- entitlement:
  `applinks:js-truck-park.chottu.link`;
- Flutter built-in handler: disabled;
- ChottuLink receives Universal Links through its iOS plugin lifecycle.

Before the first TestFlight archive, confirm that Associated Domains is enabled
for the production App ID in Apple Developer and regenerate/refresh the
distribution provisioning profile. The repository cannot perform that portal
operation.

## Closed-test checklist

Use a newly generated referral link for every deferred-install run.

Android, app installed:

1. Force-stop the app and open a Chottu referral link from a messenger.
2. Confirm the app opens and registration receives the referral code.
3. Repeat while the app is already running.
4. Open one existing parking link and one existing shared-photo link.
5. Confirm the parking details/photo viewer opens with unchanged data.

Android, app not installed:

1. Remove the app or clear all app data before the test.
2. Open a newly generated referral link.
3. Install the closed-test build from the Google Play page reached by the link.
4. Open the app from Google Play, register a new test user and confirm referral
   processing once.
5. Verify the expected `users`/`referral_stats` result with read-only inspection
   before checking the RevenueCat price presentation.

iOS/TestFlight:

1. Install the TestFlight build on a physical device.
2. Test Chottu links with the app terminated and already running.
3. Confirm Safari opens the app directly for the Chottu domain.
4. Repeat the new-user referral flow with a fresh account.
5. Test the legacy custom-scheme parking and shared-photo handoff.

## Automated verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build appbundle --release
flutter build ios --release --no-codesign
```

The platform build commands validate manifests, entitlements and plugin
integration. They do not install the build or execute application writes.

## Rollback

Revert this stage if Chottu links stop resolving, a cold-start link is lost, or
an existing parking/photo link no longer opens its previous route. No backend
rollback is required.
