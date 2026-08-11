# Release artifact provenance

## Purpose

Every uploaded Android App Bundle must be traceable to one committed source
revision. This prevents an older artifact or a bundle built from another
checkout from being uploaded under a new release description.

## Required workflow

1. Commit the feature changes.
2. Commit the `pubspec.yaml` version and build-number change.
3. Ensure the tracked working tree is clean.
4. If `android/key.properties` is absent, point `ANDROID_KEY_PROPERTIES` to the
   existing private signing-properties file.
5. Run `tool/build_release_aab.sh` from the repository root.
6. Install the generated bundle on a test device and confirm that the launcher
   shows the JS Truck Park icon, not the default Flutter icon.
7. Upload only the versioned AAB printed by the script.
8. Keep the adjacent `.build-info` file with the test record.

The script moves previous bundles out of Flutter's active output directory,
builds from `HEAD`, renames Flutter's generic `app-release.aab` output to the
versioned release filename, and verifies the internal version, Google Play
upload certificate, packaged launcher icon and release UI markers inside the
compiled `libapp.so`. The active output directory therefore contains only the
unambiguous versioned AAB. The script records the artifact SHA-256, certificate
SHA-256, launcher icon SHA-256, Git commit, branch, version and build time.
Previous bundles are preserved under `build/release-archive/`.

## Protected release markers

- `profile-invite-action`: the Invite friends action is present in the profile;
- `public-parking-details-photo-gallery`: the parking photo gesture surface is
  present;
- `public-parking-reviews-count` and `public-parking-photos-count`: the parking
  detail badges that refresh with newly submitted review content are present;
- `public-parking-details-scroll-view`: the explicit details scroll surface is
  present;
- `deep-link-cold-start-v1`: parking and shared-photo initial links are
  captured before asynchronous application startup;
- `referral-deferred-recovery-v4`: native SDK readiness, Android backup
  exclusions and the bounded deferred-attribution recovery are present in the
  release client; an early iOS organic result no longer ends the retry window.
- `referral-manual-link-fallback-v1`: registration exposes an explicit,
  validated invite-link input when iOS deferred matching does not return a
  referral code.
- `referral-link-app-routing-v2`: new referral links use Chottu app routing on
  both platforms so deferred-install attribution remains owned by Chottu.
- `referral-link-capture-v2`: Chottu links observed by the independent platform
  channel are resolved through Chottu as a cold-start delivery fallback.
- `referral-ios-early-init-v1`: Chottu starts iOS install attribution before
  Supabase, preferences, localization and other asynchronous app services.
- `referral-device-identity-v1`: referral registration refreshes and validates
  a platform-specific app-scoped device identifier instead of using an Android
  firmware build label.

The marker check does not replace Flutter tests. It protects the final handoff
between tested source and uploaded binary.

The Android launcher mipmaps are generated from
`assets/images/app_launcher_icon.png`. The platform test validates every
required density and rejects the small default Flutter placeholder assets that
were found in the Android source tree while investigating production build 49.

## Production build 49 audit

The uploaded candidate was recovered from
`build/release-archive/20260731T035344Z-2e15fb8-42435/` and inspected without
modification. It contains `versionName=1.0.15`, `versionCode=49` and the expected
Google Play upload certificate, but packages the default Flutter launcher icon.
Its compiled application also lacks `deep-link-cold-start-v1`,
`referral-deferred-recovery-v3` and the current referral-link fallback marker.

No adjacent `.build-info` exists, and build 49 was produced before the later
branches were integrated into `main`. Treat it as an untraceable legacy
artifact and do not reuse it for any track.

The local build-52 verification from the main project folder contains version
`1.0.16 (52)`, the expected upload certificate, the JS Truck Park launcher icon
and all protected deep-link/referral markers. It remains a local verification
artifact until the source changes are committed and the provenance script is
run from a clean tree.

The local build-54 candidate contains the immediate review summary refresh:
the review badge, photo badge and parking gallery are reloaded after a review
with optional photos is submitted. The verified Android artifact is
`build/app/outputs/bundle/release/JS-Truck-Park-1.0.16-54.aab` with SHA-256
`2d46585ac7b31d06148b250f4c4d108a16a83ee9b346a708ccbce79e13eb1aa6`.
It was built from the current working tree and has not been uploaded; apply the
required clean-tree workflow before any Google Play upload.

Build `1.0.16 (55)` fixes the referral registration failure found during the
iPhone closed test. Read-only inspection showed that the newly created profile
had stored `TKQ1.221114.001`, which is an Android firmware build label and was
already present on another profile. The original FlutterFlow action used
`AndroidDeviceInfo.id` even though that field represents `Build.ID`, not a
device identifier.

Build 55 reads Android's app-scoped `ANDROID_ID`, validates iOS IDFV values,
refreshes the identifier immediately before registration, and waits for any
in-flight Chottu short-link resolution before deciding whether to call
`process_referral`. No Supabase schema, policy or production data is changed.

The local Android candidate is
`build/app/outputs/bundle/release/JS-Truck-Park-1.0.16-55.aab` with SHA-256
`73c99344ffa44c190eeee0297a45f16c5f5c7c9373b9be3c389a7791c36fa0a6`.
Its manifest reports version code 55, the upload certificate matches the
expected Google Play key, and the compiled application contains
`referral-device-identity-v1`.

The matching iOS candidate was uploaded to App Store Connect and passed the
physical-device referral and UI acceptance test. On 2026-08-01 the separate
Firebase Hosting relay was deployed and externally verified to use only the
published App Store and Google Play destinations.

Because the public App Store page for `1.0.16` does not expose which internal
build Apple released, the same accepted source was assigned the unambiguous
version `1.0.17 (56)`. The signed IPA is
`build/ios/ipa/JS-Truck-Park-1.0.17-56.ipa` with SHA-256
`542c277db4d42814af3bbec968ab74e7f7fc595a41d1614533c40f34330e918d`.
Its App Store Connect upload succeeded on 2026-08-01.
App Review submission `b52da530-d722-4fce-b343-b8d19b44c908` was sent on
2026-08-01 at 14:19 and entered the `Waiting for Review` state.

## Build 57 iOS deferred-install routing

Production testing of `1.0.17 (56)` showed that Chottu recorded the referral
click, while the fresh iOS profile had no referral relation or referral stats.
Read-only inspection excluded prior use of the new iOS device identifier. The
Chottu link editor then confirmed that generated links selected `Open in
Browser` for iOS and `Open in Android App` for Android.

Build 57 restores Chottu app routing on iOS. The Hosting URL remains the link's
destination, but an uninstalled iPhone now follows Chottu's App Store fallback
without handing ownership to the browser relay first. Existing links must also
be changed to `Open in iOS App`; the client change controls newly generated
links. No Supabase contract or production data is changed.

The corrected-link production retest confirmed Android referral processing but
did not produce an iOS deferred callback. Build 58 therefore starts Chottu
immediately after Flutter binding initialization, before Supabase, preferences,
localization and other asynchronous services. The listener remains attached
after persisted app state is ready; the native plugin buffers an earlier
resolved payload until then. This maximizes the first-launch attribution window
without changing referral eligibility or backend behavior.

Local release verification completed on 2026-08-02:

- Android AAB:
  `build/app/outputs/bundle/release/JS-Truck-Park-1.0.18-58.aab`;
- AAB SHA-256:
  `25c3d2749a80baa374fd3283675995fec7b058402ce69901aeb2feab1f2c1c73`;
- iOS IPA: `build/ios/ipa/JS-Truck-Park-1.0.18-58.ipa`;
- IPA SHA-256:
  `7abe70b78ae2890fee91f5521707050986e142cbef5356c36ded9a43fffc7349`;
- signed version/build: `1.0.18 (58)`;
- production bundle ID: `com.mycompany.jstrackpark`;
- signed Associated Domains entitlement:
  `applinks:js-truck-park.chottu.link`;
- strict code-signature verification: successful;
- app-routing and early-initialization release markers: present;
- format, analyze and 370 Flutter tests: completed successfully;
- App Store Connect upload: pending.

## Build 59 parking and interaction fixes

Build 59 restores parking submission from the home `+` action and the requests
screen, including visible validation and failure feedback. Photo uploads keep
the production storage path shape with a unique timestamped filename. The SMS
confirmation screen now verifies immediately after the sixth digit, while the
profile invite dialog opens before referral-link generation and displays a
loading indicator with an explicit retry state.

Local release verification completed on 2026-08-03:

- Android AAB:
  `build/app/outputs/bundle/release/JS-Truck-Park-1.0.19-59.aab`;
- AAB SHA-256:
  `1f3b8f807134b9dc7ca8c82256a57f1f382020c04a1d73c9b71d78f8cf4234d0`;
- iOS IPA: `build/ios/ipa/JS-Truck-Park-1.0.19-59.ipa`;
- IPA SHA-256:
  `f90baa9d4fda32d26e6e4550547df7035553757bd966797028e422c2d821aac5`;
- signed version/build: `1.0.19 (59)`;
- production bundle ID: `com.mycompany.jstrackpark`;
- signed Associated Domains entitlement:
  `applinks:js-truck-park.chottu.link`;
- Android upload certificate and iOS code signature: verified;
- release, deep-link and referral startup markers: present;
- format, analyze and 372 Flutter tests: completed successfully;
- Google Play production release `59 (1.0.19)` was submitted for review at
  100% rollout on 2026-08-03;
- App Store Connect accepted build `1.0.19 (59)`, made it available to the
  internal `Dev` group, and accepted public version `1.0.19` for App Review
  with status `WAITING_FOR_REVIEW` on 2026-08-03.

No Supabase contract, schema, policy or production data change was performed.

## Build 60 profile reviews loading fix

Build 60 fixes the profile reviews/complaints screen so malformed or differently
typed Supabase timestamp payloads cannot leave the UI in an infinite loading
state. The screen now reports a retryable failure instead of spinning forever,
while valid review and report rows continue to render normally.

Local release verification completed on 2026-08-03:

- Android AAB:
  `build/app/outputs/bundle/release/JS-Truck-Park-1.0.20-60.aab`;
- AAB SHA-256:
  `535b5052ef6e3fb5a9fc5bcdf5b224c451dff0a71c47e961093e9aad890ead5b`;
- iOS IPA: `build/ios/ipa/JS-Truck-Park-1.0.20-60.ipa`;
- IPA SHA-256:
  `1ede0478ed1b79ea609298f1c13259df0c585811f8dc5b0b1fe319c0b4236368`;
- signed version/build: `1.0.20 (60)`;
- production bundle ID: `com.mycompany.jstrackpark`;
- signed Associated Domains entitlement:
  `applinks:js-truck-park.chottu.link`;
- strict iOS code-signature verification: successful;
- format, analyze and 374 Flutter tests: completed successfully;
- Google Play production release `60 (1.0.20)` was submitted for review at
  100% rollout on 2026-08-03;
- App Store Connect accepted build `1.0.20 (60)` with delivery UUID
  `e54c6a22-7ad9-4188-880b-12810c2b2724`;
- build `60` was marked `usesNonExemptEncryption=false`;
- public App Store version `1.0.19` was removed from review by the developer,
  then updated to version `1.0.20`, assigned build `60`, and submitted for
  App Review with status `WAITING_FOR_REVIEW` on 2026-08-03.

No Supabase contract, schema, policy or production data change was performed.

## Build 61 iOS referral recovery fallback

Build 61 keeps automatic Chottu attribution as the primary path, extends the
bounded recovery across an early organic result and adds an explicit validated
invite-link input to registration. A failed `process_referral` transport call
now keeps registration visible for a retry instead of silently navigating to
Home.

Local release verification completed on 2026-08-11:

- Android AAB:
  `build/app/outputs/bundle/release/JS-Truck-Park-1.0.21-61.aab`;
- AAB SHA-256:
  `772de31966c39c40b18c4917ccd0908b211685302b20a5b3751a0eeeba490352`;
- Google Play upload certificate: verified;
- Android launcher icon and protected release markers: verified;
- iOS IPA: `build/ios/ipa/JS-Truck-Park-1.0.21-61.ipa`;
- IPA SHA-256:
  `9f2398d97348b6571877443ca381a439e4113eeb98ff379a3ed5f44d22bcb59b`;
- signed version/build: `1.0.21 (61)`;
- production bundle ID: `com.mycompany.jstrackpark`;
- signed Associated Domains entitlement:
  `applinks:js-truck-park.chottu.link`;
- strict iOS code-signature verification: successful;
- `referral-deferred-recovery-v4` and
  `referral-manual-link-fallback-v1`: present in both release binaries;
- Flutter verification: formatting completed, targeted analysis has no issues,
  and all `377` tests passed;
- no production Supabase write was performed.
