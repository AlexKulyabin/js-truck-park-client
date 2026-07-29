# Referral deferred-install closed test

Target Android build: `1.0.7 (41)`.

## Scope

This run verifies the complete new-user path:

`ChottuLink click -> Google Play install -> deferred attribution -> registration
-> process_referral -> Supabase eligibility -> RevenueCat referral price`.

The client reads cached attribution immediately and retries at one and two
seconds. Registration requests the same deduplicated recovery once more before
deciding whether `process_referral` can be called.

## Preconditions

1. Upload build `1.0.7 (41)` to the intended Google Play test track and confirm
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
4. Install the app and confirm App info or the Play listing reports `1.0.7`.
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

- `version=1.0.7`;
- `build_number=41`;
- the expected Google Play upload certificate;
- `referral-deferred-recovery-v2` in `release_markers`.

Do not upload an AAB when any of these values is absent.
