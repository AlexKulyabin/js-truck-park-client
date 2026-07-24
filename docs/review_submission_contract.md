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

`SupabaseReviewSubmissionGateway` currently supports the no-photo path as one
direct `reviews` insert behind `AppWriteOperation.reviewCreate`. The review
create UI calls this service when the guarded test-write capability is enabled.
It explicitly rejects photo submissions until the staged upload and
compensation contract is implemented.

## Partial failure rule

A future implementation must use one of these reviewed backend strategies:

1. A server-owned atomic submission endpoint that validates the JWT owner,
   creates the review and photo rows, and finalizes uploaded objects only after
   all checks pass.
2. A staged upload protocol with deterministic object paths and idempotent
   compensation that removes every object and row created by a failed request.

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
