# Referral deferred-install closed test

Target Android build: `1.0.8 (42)`.

Status: passed on a physical Android device on 2026-07-30.

## Scope

This run verifies the complete new-user path:

`ChottuLink click -> Google Play install -> deferred attribution -> registration
-> process_referral -> Supabase eligibility -> RevenueCat referral price`.

The client first waits for native ChottuLink readiness, then reads cached
attribution immediately and retries after 0.5, 1 and 2 seconds. Registration
requests the same deduplicated recovery once more before deciding whether
`process_referral` can be called. Android backup rules prevent a reinstall from
restoring stale Chottu attribution, pending referral or Supabase session state.
The first launch also removes equivalent state from backup archives created by
older builds, without requiring a manual data clear.

## Verified result

The receiving device completed the full user-visible closed-test flow:

1. A newly generated Chottu referral link opened the Google Play listing.
2. Google Play installed package `com.mycompany.jstrackpark` with
   `versionName=1.0.8`, `versionCode=42` and installer
   `com.android.vending`.
3. The recipient opened the fresh installation and registered a new account.
4. The subscription screen displayed the referral discount.

No manual app-data clear was required between the Google Play installation and
registration. The successful result verifies the end-to-end user-visible path
through deferred attribution, referral processing and referral-price
eligibility for this build. No production write command was executed from the
development environment during the test.

An immediately preceding failed run was investigated separately. Device
inspection showed that Google Play had installed `1.0.7 (41)`, which did not
contain the backup and restored-state fixes. That run is an artifact-version
mismatch and is not a failure of `1.0.8 (42)`.

The Supabase row-level checkpoints below remain useful for future diagnostics;
they were not independently captured as acceptance evidence after the
successful user-visible run.

## iOS probabilistic fallback

Build `1.0.21 (61)` adds a deterministic user-controlled fallback for an iOS
install that Chottu reports as organic. On the registration screen, tap
`Add invite link`, paste the original Chottu URL and confirm that the control
changes to `Invite link saved` before completing registration. The URL is
resolved through Chottu and the existing `process_referral` contract remains
the only backend write boundary.

This fallback is optional for genuinely organic registrations. It does not
read the clipboard automatically and does not change the referral eligibility
rules.

## Preconditions

1. Upload build `1.0.8 (42)` to the intended Google Play test track and confirm
   that the test account can see that exact version.
2. Explicitly deploy hosting commit `2b2572a` from
   `js-truck-park-legal-main` after production-write approval.
3. Confirm the live relay contains the published Google Play URL and no
   `apps/internaltest` URL.
4. Use a physical Android device with a personal Google account.
5. Use a phone number and device that are eligible for a new referral under the
   existing server rules.
6. Generate a new referral URL for this run. Do not reuse a link from an older
   install attempt.

## Full Google Play run

1. Confirm JS Truck Park is not installed on the receiving device.
2. Send the new referral link through a messenger and tap it there.
3. Confirm the link opens the JS Truck Park listing in Google Play.
4. Install the app and confirm App info or the Play listing reports `1.0.8`.
5. Open the app from Google Play and leave it open through splash/onboarding.
6. Register the fresh test account normally.
7. Open the subscription screen only after registration has completed.

## Read-only checkpoints

Check each layer in order. Do not skip directly to RevenueCat.

1. Chottu dashboard contains the new link click.
2. Chottu attribution reports the install as attributed rather than organic.
3. The new Supabase user has a non-null `referred_by_id`.
4. `referral_stats` contains one row for the new referee/device.
5. The subscription screen reports referral eligibility and displays the
   referral product price.

Interpret failures at the first missing checkpoint:

| First missing checkpoint | Owner |
|---|---|
| Chottu click | generated/shared URL or Chottu domain |
| attributed install | Chottu/Google Play matching or test conditions |
| `referred_by_id` and stats | client recovery or `process_referral` contract |
| referral price | RevenueCat offering/product configuration or cache |

## Artifact proof

The adjacent `.build-info` file must report:

- `version=1.0.8`;
- `build_number=42`;
- the expected Google Play upload certificate;
- `referral-deferred-recovery-v4` in `release_markers`;
- `referral-manual-link-fallback-v1` in `release_markers`.

Do not upload an AAB when any of these values is absent.
