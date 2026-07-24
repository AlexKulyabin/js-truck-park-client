# Storage policy baseline

Дата: 2026-07-24.

Scope: Storage buckets and object path contracts used by the Flutter client.
This document is a versioned reference for the next Storage hardening stages.
It does not contain production data and does not require production write
operations.

## Buckets

| Bucket | Public | Limit | MIME |
|---|---:|---:|---|
| `assets` | yes | platform default | unrestricted metadata |
| `avatars` | yes | 5 MiB | `image/jpeg`, `image/png`, `image/webp` |
| `parking_content` | yes | 5 MiB | `image/jpeg`, `image/png`, `image/webp` |

Public buckets are part of the current UI contract: uploaded image URLs are
stored as public URLs and rendered directly by Flutter widgets. Public read
does not mean public write.

## Flutter path contract

| Flow | Bucket | Object path |
|---|---|---|
| Registration avatar | `avatars` | `users/<auth.uid()>/<filename>` |
| Edit profile avatar | `avatars` | `users/<auth.uid()>/<filename>` |
| Create parking photos | `parking_content` | `parkings/<parkingId>/<index>/<timestamp>.<ext>` |
| Create review photos | `parking_content` | `parkings/<parkingId>/reviews/<reviewId>/<index>/<timestamp>.<ext>` |
| Marker asset | `assets` | `icnLocation.png` |

The upload helper returns public URLs and does not provide signed URLs. The
delete helper can remove an object by public URL, but production Flutter
callers for deletion were not found during the static scan.

## Current risk snapshot

The production read-only audit recorded these Storage risks:

- `Avatar_Upload`, `Avatar_Update`, and `Avatar_Delete` are bucket-scoped and
  do not enforce the `users/<auth.uid()>/...` owner path.
- `parking_content` has duplicated write policies with inconsistent path
  assumptions.
- Stale policies for the missing `parking-images` bucket still exist.

The local Supabase schema catalog in this repository includes managed Storage
tables/functions, but not the hosted project's custom Storage policies. Before
applying hardening to production or staging, run a read-only policy diff against
the target project and confirm that no additional production-only policy name is
left permissive.

## Target write contract

The next hardening stages should preserve public reads and bucket settings while
restricting writes:

- avatars: authenticated users may insert, update, and delete only objects under
  `users/<auth.uid()>/...`;
- parking content: authenticated users may insert/update/delete direct parking
  objects only for a parking they own, and review objects only for a review they
  authored;
- `assets` stays read-only for the mobile client.

## Verification checklist

- owner avatar upload/update/delete succeeds;
- cross-user avatar insert/update/delete fails;
- owner parking photo upload/update/delete succeeds for
  `parkings/<parkingId>/...`;
- review author upload/update/delete succeeds for
  `parkings/<parkingId>/reviews/<reviewId>/...`;
- cross-user parking content mutation fails;
- public image read keeps working for existing URLs;
- wrong bucket/path/MIME/oversize fails.
