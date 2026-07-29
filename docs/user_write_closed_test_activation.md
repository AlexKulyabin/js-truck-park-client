# User write closed-test activation

Date: 2026-07-29

Target build: `1.0.5 (39)`.

Status: client capabilities prepared for the next Android closed-test Release.
No Supabase migration, policy change or production write command is part of
this stage.

## Build artifact

- file: `build/app/outputs/bundle/release/JS-Truck-Park-1.0.5-39.aab`;
- SHA-256:
  `dac648e0cacbbb205847bff4a2249592adc0030b2aaf9ce89d16b25b76934974`;
- upload certificate SHA-256:
  `AD:AE:70:BC:2E:04:2A:C4:C6:56:66:B0:7E:E3:F5:E1:78:39:D2:1F:BD:7E:E9:49:A4:9A:1A:48:2C:7B:DC:E5`;
- validation: Gradle Release bundle and signing tasks passed, compressed data
  is valid, and `jarsigner` reported `jar verified`;
- publication status: built locally, not uploaded to Google Play.

## Scope

The next Release build exposes the existing user flows needed for a full
closed test. It does not grant moderation or post-publication review mutation
rights.

| User flow | Release status | Boundary |
|---|---|---|
| Create a parking with photos | enabled, existing behavior | new parking stays `pending` for moderation |
| Toggle own favorite | enabled, existing capability | authenticated owner pair only |
| Create a parking report | enabled, existing capability | authenticated reporter only |
| Create one review | enabled in this stage | authenticated author and existing UI duplicate guard |
| Attach photos to a new review | enabled in this stage | JPEG/PNG/WebP, at most 1920 x 1920 and 5 MiB each |
| Update a published review | disabled | no production capability |
| Delete a published review | disabled | no production capability |
| Add, replace or delete review photos later | disabled | creation-only photo capability |
| Edit profile/avatar | existing legacy Release behavior | not widened by this stage |
| Approve, reject or delete parking content | unavailable to ordinary users | moderation/admin boundary |

The client has no user-facing parking edit flow in the current route set.
Parking editing is therefore not claimed as part of this activation.

## Safety contract

- `reviewCreate` is enabled only for production Release or an explicitly
  configured non-production test build.
- `reviewPhotoCreate` is a separate operation and applies only to photos in a
  new review submission.
- `reviewUpdate` and `reviewDelete` remain false in production Release.
- the service validates authenticated identity, parking ID, rating range,
  content presence, image MIME, dimensions and byte size before the gateway;
- the gateway uses deterministic owner paths and best-effort compensation if a
  photo upload or photo-row insert fails;
- client gates are not a security boundary; Supabase RLS and Storage policies
  remain authoritative.

## Android closed-test checklist

Use designated test accounts and clearly identifiable test content.

1. Install the new build from the Google Play closed-test track.
2. Create a parking without photos and confirm it appears in Pending requests.
3. Create a parking with one valid photo and confirm moderation details render
   the same photo.
4. Toggle a favorite twice and confirm the details sheet stays mounted.
5. Submit one report and confirm it appears only for its author/admin contract.
6. Create a text-only review and confirm a second review for the same parking
   is blocked by the current UI rule.
7. With a different designated account, create a review with one JPEG or WebP
   photo below 5 MiB and no larger than 1920 x 1920.
8. Confirm the review and every selected photo appear together after refresh
   and after restarting the app.
9. Confirm no edit or delete action is offered for the published review.
10. Try an oversize or unsupported image and confirm no review write starts.
11. Inspect `reviews`, `parking_photos` and Storage read-only: author IDs,
    parking IDs, review IDs and object paths must match the test submission.
12. Check logs for permission failures and verify they contain no JWT, phone
    number or raw SQL details.

## Stop conditions

Do not promote the tested artifact beyond the closed-test track if:

- a review is created without all selected photos;
- an uploaded object remains after a failed submission;
- a user can update/delete a published review or another user's content;
- a photo row has a different `user_id`, `parking_id` or `review_id`;
- the same user can create duplicate reviews for one parking;
- a failed write closes or corrupts the parking details sheet;
- current hosted RLS or Storage behavior differs from the documented owner
  contract.

## Deferred iOS prerequisite

Android testing may proceed now. Before the next iOS/TestFlight archive, finish
the Associated Domains and provisioning-profile steps recorded in
`docs/deep_link_platform_integration.md`.

## Rollback

Revert the client capability commit. No backend rollback is required because
this stage does not alter Supabase schema, policies or data.
