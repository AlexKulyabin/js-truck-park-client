# Integration connectivity report

Date: 2026-07-22
Mode: anonymous/read-only production API diagnostics

No response bodies, database rows, JWTs, phone numbers or user coordinates were
recorded.

| Check | Result | Interpretation |
|---|---:|---|
| Supabase Auth health | HTTP 200 | Auth service is reachable |
| PostgREST OpenAPI root | HTTP 401 | schema introspection is not available with the publishable client context |
| public marker asset, one-byte range | HTTP 206 | existing public Storage asset is reachable |
| `get_filtered_parkings` with a bounded static viewport | HTTP 200 | the Home read RPC accepts the current publishable client contract |

The RPC response was discarded after recording its status and byte count. No
production write endpoint was called.

This proves transport-level compatibility only. It does not prove RLS coverage,
RPC implementation safety, result correctness, rate limits, indexes or behavior
for authenticated users.
