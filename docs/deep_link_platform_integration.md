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

On Android, deferred attribution recovery starts without blocking the first
Flutter frame. The Flutter plugin returns from `init` before the native SDK can
finish Install Referrer initialization, so recovery first polls native
readiness for a bounded 3.75 seconds. It then reads Chottu attribution
immediately and retries after 0.5, 1 and 2 seconds when the SDK cache is still
empty. A completed organic result stops the retry schedule, and concurrent
callers share one in-flight recovery operation. Referral codes are persisted
through the existing `FFAppState.tempReferralCode` contract and are never
written to logs.
The first-run splash allows four seconds for that bounded recovery, and the
registration action requests the same deduplicated recovery once more before
deciding whether to call `process_referral`. It does not call the RPC when no
verified referral code is available.

Flutter's built-in deep-link handler is disabled for release. This prevents it
from navigating to a Chottu short-link path before the ChottuLink SDK resolves
the destination. The existing `app_links` dependency now owns the legacy
custom-scheme handoff.

Android Auto Backup excludes `chottu_prefs.xml` and
`FlutterSharedPreferences.xml` from cloud backup and device transfer. This
prevents a reinstall from restoring Chottu's completed-attribution flag, a
pending referral code or a Supabase session from the previous installation.
Other application files remain eligible for the existing Android backup
behavior. The backup rules themselves do not clear data from the current
installation.

Build `1.0.8 (42)` also handles backup archives created before these exclusions
existed. Before Flutter and ChottuLink initialize, Android clears Chottu's
transient preferences once per installation. On a fresh install, it also
clears restored Flutter preferences so an old Supabase session or pending
referral cannot leak into registration. A marker in Android's no-backup storage
prevents this cleanup from repeating on later launches. An in-place update
keeps the user's Flutter preferences and authenticated session.

The coordinator allowlists only:

- `/homePage`: `targetParkingId`, `targetLat`, `targetLng`;
- `/sharedPhotoView`: `photoUrl`, `address`, `date`;
- `/splash`: `ref`.

Unknown query parameters are not forwarded into application navigation.

`app_links` is instantiated and its initial URI is requested before Supabase,
preferences and other asynchronous startup work. The coordinator subscribes to
the warm-link stream before consuming that captured URI and deduplicates the
initial event if Android also publishes it through the stream. This preserves
parking and shared-photo navigation when the app is launched from a terminated
state without opening the same route twice during a warm launch.

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

## Deferred Apple portal action

Decision date: 2026-07-29.

Associated Domains activation in Apple Developer is intentionally deferred
while Android closed testing validates the user write flows. This does not
block Android builds, Google Play closed testing, review creation or photo
submission.

This action is a release blocker before the next iOS/TestFlight archive is
created or uploaded:

1. Enable `Associated Domains` for the production App ID
   `8XNBY3768H.com.mycompany.jstrackpark` in Apple Developer.
2. Regenerate the App Store distribution provisioning profile, or let Xcode
   refresh it with automatic signing.
3. Confirm the signed archive contains
   `applinks:js-truck-park.chottu.link`.
4. Install the new TestFlight build on a physical device and test a new Chottu
   link with the app terminated and already running.

Do not upload an iOS build that contains the entitlement until the App ID and
provisioning profile both include the capability. The repository cannot perform
these Apple portal operations.

## Closed-test checklist

Use a newly generated referral link for every deferred-install run.

Android, app installed:

1. Force-stop the app and open a Chottu referral link from a messenger.
2. Confirm the app opens and registration receives the referral code.
3. Repeat while the app is already running.
4. Open one existing parking link and one existing shared-photo link.
5. Confirm the parking details/photo viewer opens with unchanged data.

Android, app not installed:

1. Remove the app. Builds containing the backup exclusions must not require a
   separate manual data clear.
2. Open a newly generated referral link.
3. Install the closed-test build from the Google Play page reached by the link.
4. Open the app from Google Play, register a new test user and confirm referral
   processing once.
5. Verify the expected `users`/`referral_stats` result with read-only inspection
   before checking the RevenueCat price presentation.

The generated referral URL must be new for each run. On first launch, allow the
app to remain open through the splash/onboarding transition so the bounded
readiness and attribution retries can complete.

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
