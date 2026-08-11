# Parking share cold-start closed test

Target Android build: `1.0.9 (43)`.

## Scope

This run verifies that the existing Hosting relay opens parking and shared
photo routes when the application is terminated or already running. It also
guards the separate Chottu referral owner from the startup change.

The observed failing `1.0.8 (42)` Intent was valid and contained:

- custom scheme `jstrackpark`;
- host `js-truck-park.web.app`;
- route `/homePage`;
- `targetParkingId`, `targetLat` and `targetLng`.

The client previously created `app_links` after the first Flutter frame, so the
cold-start event could be delivered before the listener existed. Build 43
captures the initial URI before asynchronous application startup, subscribes
to warm events and deduplicates an initial event repeated by the stream.

## Closed-test checklist

1. Update the receiving device to `1.0.9 (43)` from the intended Google Play
   test track.
2. Force-stop JS Truck Park and open a newly shared parking link from a
   messenger.
3. Confirm the app opens the map and immediately presents the requested parking
   details.
4. Close the parking details, leave the app running and open the same link
   again. Confirm the details open once without a duplicate sheet.
5. Force-stop the app and open a newly shared photo link. Confirm the requested
   photo viewer opens with its address and optional date.
6. Open one Chottu referral link while the app is installed and confirm its
   referral route remains owned by ChottuLink.

No user deletion, fresh registration or production database write is required
for the parking and photo checks.

## Artifact proof

The adjacent `.build-info` file must report:

- `version=1.0.9`;
- `build_number=43`;
- the expected Google Play upload certificate;
- `deep-link-cold-start-v1` in `release_markers`;
- `referral-deferred-recovery-v4` in `release_markers`.

Do not upload an AAB when any of these values is absent.

## Rollback

Revert the cold-start feature commit if a parking or photo link no longer opens
its previous route, a warm link opens twice, or Chottu links are consumed by
the legacy Hosting coordinator. No backend rollback is required.
