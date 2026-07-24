# Profile update safety contract

## Current production behavior

The legacy edit profile screen uploads a selected avatar to the public
`avatars` bucket first, then updates the `users` row with `full_name`, optional
`avatar_url` and `updated_at`.

Those operations are not atomic. If Storage upload succeeds but the row update
fails, an avatar object can be left without the matching profile reference.
This stage does not change or call that production flow.

## Prepared client boundary

`UserProfileService` now defines:

- a typed `UpdateUserProfileCommand` for owner id, name, update timestamp and
  optional avatar draft metadata;
- validation for owner identity and avatar metadata;
- immutable `PreparedUserProfileUpdate` data;
- an explicit `profileUpdate` write capability that remains disabled in every
  build;
- a single `UserProfileUpdateGateway.updateProfileAtomically` operation.

There is intentionally no Supabase update gateway implementation and no UI
wiring in this stage. The gateway contract forbids promoting the current
client-side Storage upload plus row update sequence as the target architecture.

## Partial failure rule

A future implementation must use one of these reviewed strategies:

1. A server-owned endpoint that validates the JWT owner, stores or finalizes the
   avatar object and updates the `users` row as one operation.
2. A staged upload protocol with deterministic owner-scoped paths and
   idempotent compensation that removes every object created by a failed
   request.

Returning success is allowed only when the profile row and avatar object are in
the same intended state. Retrying the same request must not create duplicate or
orphaned avatar objects.

## Activation prerequisites

- version-controlled backend contract and migrations;
- owner, cross-user and anonymous RLS tests for `users`;
- owner, cross-user and anonymous Storage policy tests for `avatars`;
- failure tests for avatar upload/finalization and row update boundaries;
- staging verification without production writes;
- a separate commit that implements the gateway and wires the UI;
- a separate reviewed change that enables `AppWriteOperation.profileUpdate`.

The concrete policy gate and stop conditions are tracked in
`profile_security_activation_checklist.md`.
