# Release artifact provenance

## Purpose

Every uploaded Android App Bundle must be traceable to one committed source
revision. This prevents an older artifact or a bundle built from another
checkout from being uploaded under a new release description.

## Required workflow

1. Commit the feature changes.
2. Commit the `pubspec.yaml` version and build-number change.
3. Ensure the tracked working tree is clean.
4. Run `tool/build_release_aab.sh` from the repository root.
5. Upload only the versioned AAB printed by the script.
6. Keep the adjacent `.build-info` file with the test record.

The script builds from `HEAD`, verifies release UI markers inside the compiled
`libapp.so`, copies the bundle to a versioned filename, and records its SHA-256,
Git commit, branch, version and build time.

## Protected release markers

- `profile-invite-action`: the Invite friends action is present in the profile;
- `public-parking-details-photo-gallery`: the parking photo gesture surface is
  present;
- `public-parking-details-scroll-view`: the explicit details scroll surface is
  present.

The marker check does not replace Flutter tests. It protects the final handoff
between tested source and uploaded binary.
