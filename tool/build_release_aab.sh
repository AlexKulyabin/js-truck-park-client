#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Tracked files must be committed before a release build." >&2
  exit 1
fi

version_line="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)"
version_name="${version_line%%+*}"
build_number="${version_line##*+}"

if [[ -z "$version_name" || -z "$build_number" || "$version_name" == "$build_number" ]]; then
  echo "Unable to read version and build number from pubspec.yaml." >&2
  exit 1
fi

git_sha="$(git rev-parse HEAD)"
git_branch="$(git branch --show-current)"
output_dir="build/app/outputs/bundle/release"
artifact="$output_dir/JS-Truck-Park-${version_name}-${build_number}.aab"
build_info="${artifact}.build-info"

flutter build appbundle --release
cp "$output_dir/app-release.aab" "$artifact"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
unzip -q "$artifact" 'base/lib/arm64-v8a/libapp.so' -d "$tmp_dir"

compiled_strings="$tmp_dir/libapp.strings"
strings "$tmp_dir/base/lib/arm64-v8a/libapp.so" > "$compiled_strings"

for marker in \
  'profile-invite-action' \
  'public-parking-details-photo-gallery' \
  'public-parking-details-scroll-view'; do
  if ! grep -Fq "$marker" "$compiled_strings"; then
    echo "Release marker missing from AAB: $marker" >&2
    exit 1
  fi
done

artifact_sha="$(shasum -a 256 "$artifact" | awk '{print $1}')"
cat > "$build_info" <<EOF
artifact=$(basename "$artifact")
version=$version_name
build_number=$build_number
git_commit=$git_sha
git_branch=$git_branch
sha256=$artifact_sha
built_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
release_markers=profile-invite-action,public-parking-details-photo-gallery,public-parking-details-scroll-view
EOF

printf 'AAB: %s\n' "$artifact"
printf 'Build info: %s\n' "$build_info"
printf 'SHA-256: %s\n' "$artifact_sha"
