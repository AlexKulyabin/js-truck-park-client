# Review submission safety contract

## Legacy production behavior

Before the guarded service path, the review screen inserted a `reviews` row
first, then uploaded each file to Storage and inserted one `parking_photos` row
per URL. Those operations were not atomic. A failed upload or row insert could
leave a review with only some photos, or an uploaded object without its
database row.

The current UI is wired through `ReviewSubmissionService`, but the write
capability is still disabled by default and can only be enabled for guarded
non-production test builds.

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
are visible together. The client uses deterministic object paths and best-effort
compensation to limit duplicate/orphan risk, but a fully duplicate-safe retry
contract still belongs in a future server-owned endpoint or RPC with an
explicit idempotency key.

Review deletion uses the inverse cleanup order in the prepared client service:
capture owner-scoped photo URLs, delete the owner-scoped review row, then remove
public Storage objects best-effort. If Storage cleanup fails after the row is
gone, the result records failed cleanup count; a future backend job can retry
orphan cleanup without restoring the deleted review.

## Activation prerequisites

- version-controlled backend contract and migrations;
- owner, cross-user and anonymous RLS/Storage policy tests;
- failure tests for every upload and insert boundary;
- cleanup tests for Storage upload failure and photo-row insert failure;
- server-side idempotency key before enabling broad production retries;
- staging verification without production writes;
- a separate commit that wires the UI to `ReviewSubmissionService`;
- a separate photo-flow commit with compensation before photo submission is
  enabled.
