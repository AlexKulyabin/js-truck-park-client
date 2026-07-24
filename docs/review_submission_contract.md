# Review submission safety contract

## Current production behavior

The legacy review screen inserts a `reviews` row first, then uploads each file
to Storage and inserts one `parking_photos` row per URL. These operations are
not atomic. A failed upload or row insert can leave a review with only some
photos, or an uploaded object without its database row.

This stage does not change or call that production flow.

## Prepared client boundary

`ReviewSubmissionService` defines:

- a typed `ReviewSubmissionCommand` for owner, parking, comment, five scores,
  timestamp and photo metadata;
- validation matching the current UI eligibility rule and score range;
- immutable `PreparedReviewSubmission` data;
- an explicit `reviewCreate` write capability that remains disabled in every
  build;
- a single `ReviewSubmissionGateway.submitAtomically` operation.

`SupabaseReviewSubmissionGateway` supports review creation behind
`AppWriteOperation.reviewCreate`. The review create UI calls this service when
the guarded test-write capability is enabled. Photo uploads keep the
FlutterFlow picker constraints: `maxWidth=1920`, `maxHeight=1920`,
`imageQuality=80`, JPEG/PNG/WebP only, and the Supabase bucket limit of 5 MiB.

## Partial failure rule

The current client implementation uses the staged upload strategy:

1. Create the owner-scoped `reviews` row.
2. Upload each image to
   `parking_content/parkings/<parkingId>/reviews/<reviewId>/<index>/...`.
3. Insert one owner-scoped `parking_photos` row per uploaded object.
4. If any step fails, delete the created review row and remove every uploaded
   public Storage object best-effort.

Returning success is allowed only when the review and every requested photo
are visible together. Retrying the same submission must not create duplicates.

Review deletion uses the inverse cleanup order in the prepared client service:
capture owner-scoped photo URLs, delete the owner-scoped review row, then remove
public Storage objects best-effort. If Storage cleanup fails after the row is
gone, the result records failed cleanup count; a future backend job can retry
orphan cleanup without restoring the deleted review.

## Activation prerequisites

- version-controlled backend contract and migrations;
- owner, cross-user and anonymous RLS/Storage policy tests;
- failure tests for every upload and insert boundary;
- idempotency and cleanup tests;
- staging verification without production writes;
- a separate commit that wires the UI to `ReviewSubmissionService`;
- a separate photo-flow commit with compensation before photo submission is
  enabled.
