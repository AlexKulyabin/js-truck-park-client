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

## Guest iOS smoke test

The integration build was installed and launched on an iPhone 17 Simulator. A
guest completed onboarding and reached Home with the `READ ONLY` and `DEBUG`
banners visible. No authenticated session or write-capable screen was used.

Home rendered its map controls, search and filter UI. Native Google map tiles did
not load because the simulator repeatedly failed DNS resolution for
`clients4.google.com` (`NSURLErrorDomain -1003`). The macOS host resolved the same
hostname successfully, so this is a simulator/VPN/DNS-path issue rather than a
Supabase failure. A Web Maps key is unrelated to this native iOS check; web map
integration remains untested.
