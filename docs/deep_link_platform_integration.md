# Deep-link platform integration

Date: 2026-08-01

Status: implemented in build `1.0.16 (55)` and verified on a physical iPhone.
The public Hosting relay was deployed on 2026-08-01. No Supabase schema,
policies or production data were changed.

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
- further Firebase Hosting changes after the public-store fallback deployment;
- referral eligibility, Supabase RPC or RevenueCat behavior;
- reviews, parking writes or production data;
- Android/iOS build-number changes.

## Ownership contract

Each inbound URL family has one application-level owner:

| URL | Owner | Result |
|---|---|---|
| `https://js-truck-park.chottu.link/...` | ChottuLink SDK, with `app_links` delivery fallback | resolve referral/deferred metadata and persist `ref` |
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

The Chottu native event remains the primary referral channel. If `app_links`
also observes a Chottu URL during a cold or warm launch, the coordinator does
not navigate to that short path or parse it itself. It passes the URL back to
`ChottuLink.getAppLinkDataFromUrl`, then persists the referral code from the
resolved destination. This closes the startup race where the native event can
arrive before Dart attaches the Chottu event listener.

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

## Apple portal activation

Completed on 2026-07-31:

1. `Associated Domains` is enabled for the production App ID
   `8XNBY3768H.com.mycompany.jstrackpark` in Apple Developer.
2. The App Store distribution profile
   `JS Truck Park App Store 2026-07-31` was generated with the current Apple
   Distribution certificate.
3. The signed `1.0.16 (50)` archive includes
   `applinks:js-truck-park.chottu.link`.
4. Xcode validation completed with only the known ChottuLinkSDK dSYM warning,
   and build 50 was uploaded to App Store Connect.

Physical-device Universal Link verification remains a TestFlight acceptance
step. Chottu's current troubleshooting guide explicitly excludes TestFlight
from deferred deep-link testing, so an iOS referral discount after installation
must be verified with a local Xcode install or a live App Store build. The
reproducible archive procedure and known dSYM warning are recorded in
`docs/ios_testflight_archive.md`.

## Build 50 TestFlight result

Physical-device testing on 2026-07-31 confirmed that a fresh Chottu referral
link reached the production App Store listing, but the referral was not
recovered after build 50 was installed from TestFlight. Registration completed
without referral eligibility and the subscription screen kept the standard
price.

The Android-only guard in `recoverChottuReferral()` was a client defect. Build
51 enables the existing bounded Chottu attribution recovery on both Android and
iOS, but TestFlight cannot prove the deferred-install result because that path
is unsupported by Chottu. The signed build 51 package was accepted for App
Store Connect processing on 2026-07-31.

## Build 52 link fallback

A referral link generated by the Google Play production build was observed
hanging on a blank `js-truck-park.chottu.link` page inside Telegram on iOS.
Build 52 keeps Android in Chottu `app` mode and uses Chottu `browser` mode for
iOS. The iOS web path therefore reaches the existing Hosting relay, which
attempts the custom-scheme handoff and then redirects to the store. New links
use the same minimal Android creation parameters as the proven build 42 flow,
and the profile refuses to share an invalid or error response as though it were
a URL.

The Hosting source fix is committed as `2b2572a` in the separate
`js-truck-park-legal-main` repository. It was deployed to the
`js-truck-park` Firebase Hosting site on 2026-08-01 after the contract tests and
dry run passed. The live relay now uses the published Google Play listing and
App Store listing and contains neither the Internal Test URL nor the TestFlight
URL.

## Build 53 Android referral capture

The last registration observed on 2026-07-31 created a production profile and
recorded its device id, but `referred_by_id` remained null. This read-only
checkpoint places the failure before subscription-price selection. No
production data was changed during the investigation.

The branch audit found no omitted referral commit: the standalone
`agent/referral-deep-link-fix` change was integrated as `341eec8`, and the
complete Android recovery chain that passed in build `1.0.8 (42)` is present in
`main`. Build 53 restores the minimal proven Android link-creation parameters
and adds the independent Chottu short-URL resolution fallback described above.

## Build 55 referral registration identity

Read-only inspection after the iPhone test found a new profile without
`referred_by_id` and with the Android firmware label `TKQ1.221114.001` in
`last_device_id`. That value was also present on an older profile. The original
custom action had treated `AndroidDeviceInfo.id` (`android.os.Build.ID`) as a
unique device identifier, so unrelated Android devices on the same firmware
could collide with the server's existing one-referral-per-device rule.

Build 55 uses Android's app-scoped `Settings.Secure.ANDROID_ID`, keeps iOS on a
validated `identifierForVendor`, and refreshes the value on the registration
action itself. Registration also waits for an in-flight Chottu URL resolution
before it falls back to deferred attribution. This closes the installed-link
race where the app could open successfully but registration could still see no
pending referral code.

The production referral function and data were not modified. The historical
profile observation remains diagnostic evidence only; it is not treated as an
iOS identifier because a valid iOS IDFV has UUID form.

Physical-device testing of build 55 confirmed the complete installed-app iOS
flow: the referral link opened the application, a fresh user was created, and
the referral discount was applied. This is the accepted production candidate.

## Build 61 iOS referral recovery fallback

The live App Store deferred-install flow can still be reported as organic when
Chottu cannot match the pre-install click to the first iOS launch. Build 61
keeps the automatic SDK path as the primary behavior but no longer treats the
first cached organic result as the end of the bounded recovery window. It
performs one additional read and allows 6.5 seconds in total for a later
attributed result.

Registration now exposes an optional invite-link action. The recipient can
explicitly paste the Chottu short URL they received; the app resolves it
through the existing Chottu SDK boundary, persists only the referral code and
shows a confirmed state before registration is completed. Clipboard contents
are read only after the user taps the paste icon. Invalid links remain in the
sheet with localized feedback.

The existing `process_referral` API and Supabase eligibility rules are
unchanged. A transport failure no longer silently navigates to Home while a
pending referral exists; registration stays visible and offers a retry. No
Supabase schema, policy or production data change is included.

## Build 57 iOS deferred-install routing

The first live App Store deferred-install test of `1.0.17 (56)` produced a
Chottu click but no referral relation or referral stats for the fresh iOS
profile. Read-only inspection excluded device reuse. The generated link's
Chottu settings showed `Open in Browser` on iOS, while Android used `Open in
Android App`. The browser workaround introduced in build 52 therefore handed
the uninstalled flow to the Hosting relay before Chottu could own the App Store
fallback and recover install attribution.

Build 57 restores `CLDynamicLinkBehaviour.app` on iOS. Existing links require
the matching `Open in iOS App` setting in Chottu; newly generated links receive
it from the client. The destination URL remains the Hosting relay, and Android
behavior is unchanged. No Supabase contract or production data is modified.

The corrected-link retest confirmed the complete Android referral flow, but
the iOS install was not matched. Chottu documents that iOS deferred matching is
probabilistic and emits no callback below its confidence threshold. Build 58
also moves SDK initialization to the first asynchronous operation after Flutter
binding setup, ahead of Supabase, preferences and localization. The native
plugin buffers a resolved payload until the Dart listener is attached after
persisted state initialization.

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

iOS/TestFlight build 51:

1. Install the TestFlight build on a physical device.
2. Test Chottu links with the app terminated and already running.
3. Confirm the installed-app referral code reaches registration.
4. Test the legacy custom-scheme parking and shared-photo handoff.

Do not use TestFlight price state as deferred-install acceptance evidence.
Verify the iOS install-to-discount path with a local Xcode install after a fresh
click, or later with a live App Store build and a fresh account/device.

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
