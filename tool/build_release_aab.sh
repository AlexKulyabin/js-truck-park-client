#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmp_dir=""
created_signing_link=false

cleanup() {
  if [[ -n "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
  if [[ "$created_signing_link" == true ]]; then
    rm -f android/key.properties
  fi
}

trap cleanup EXIT

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
expected_upload_sha256="AD:AE:70:BC:2E:04:2A:C4:C6:56:66:B0:7E:E3:F5:E1:78:39:D2:1F:BD:7E:E9:49:A4:9A:1A:48:2C:7B:DC:E5"

if [[ ! -f android/key.properties ]]; then
  if [[ -z "${ANDROID_KEY_PROPERTIES:-}" || ! -f "$ANDROID_KEY_PROPERTIES" ]]; then
    echo "Release signing is missing. Set ANDROID_KEY_PROPERTIES to the existing key.properties file." >&2
    exit 1
  fi
  ln -s "$ANDROID_KEY_PROPERTIES" android/key.properties
  created_signing_link=true
fi

mkdir -p "$output_dir"
shopt -s nullglob
previous_artifacts=("$output_dir"/*.aab "$output_dir"/*.aab.build-info)
if (( ${#previous_artifacts[@]} > 0 )); then
  archive_dir="build/release-archive/$(date -u '+%Y%m%dT%H%M%SZ')-$(git rev-parse --short HEAD)-$$"
  mkdir -p "$archive_dir"
  mv "${previous_artifacts[@]}" "$archive_dir/"
fi
shopt -u nullglob

flutter build appbundle --release
if [[ ! -f "$output_dir/app-release.aab" ]]; then
  echo "Flutter did not produce the expected app-release.aab." >&2
  exit 1
fi
mv "$output_dir/app-release.aab" "$artifact"

tmp_dir="$(mktemp -d)"
unzip -q "$artifact" \
  'base/lib/arm64-v8a/libapp.so' \
  'base/manifest/AndroidManifest.xml' \
  'base/res/mipmap-xxxhdpi-v4/ic_launcher.png' \
  -d "$tmp_dir"

compiled_strings="$tmp_dir/libapp.strings"
strings "$tmp_dir/base/lib/arm64-v8a/libapp.so" > "$compiled_strings"

for marker in \
  'profile-invite-action' \
  'public-parking-details-photo-gallery' \
  'public-parking-reviews-count' \
  'public-parking-photos-count' \
  'public-parking-details-scroll-view' \
  'deep-link-cold-start-v1' \
  'referral-deferred-recovery-v3' \
  'referral-link-fallback-v1' \
  'referral-link-capture-v2' \
  'referral-device-identity-v1'; do
  if ! grep -Fq "$marker" "$compiled_strings"; then
    echo "Release marker missing from AAB: $marker" >&2
    exit 1
  fi
done

android_sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
if [[ ! -d "$android_sdk/build-tools" ]]; then
  echo "Android SDK build-tools are required to verify the AAB manifest." >&2
  exit 1
fi
aapt2="$(find "$android_sdk/build-tools" -type f -name aapt2 | sort -V | tail -1)"
if [[ -z "$aapt2" ]]; then
  echo "aapt2 was not found in Android SDK build-tools." >&2
  exit 1
fi

cp "$tmp_dir/base/manifest/AndroidManifest.xml" "$tmp_dir/AndroidManifest.xml"
(cd "$tmp_dir" && zip -q manifest.apk AndroidManifest.xml)
manifest_dump="$("$aapt2" dump xmltree "$tmp_dir/manifest.apk" --file AndroidManifest.xml)"
if ! grep -Eq "versionCode.*=${build_number}( |$)" <<<"$manifest_dump"; then
  echo "AAB versionCode does not match pubspec.yaml build number $build_number." >&2
  exit 1
fi
if ! grep -Fq "versionName" <<<"$manifest_dump" ||
    ! grep -Fq "=\"$version_name\"" <<<"$manifest_dump"; then
  echo "AAB versionName does not match pubspec.yaml version $version_name." >&2
  exit 1
fi

launcher_icon="$tmp_dir/base/res/mipmap-xxxhdpi-v4/ic_launcher.png"
launcher_icon_size="$(stat -f '%z' "$launcher_icon")"
if (( launcher_icon_size < 10000 )); then
  echo "AAB launcher icon matches the small Flutter placeholder profile." >&2
  exit 1
fi
launcher_icon_sha="$(shasum -a 256 "$launcher_icon" | awk '{print $1}')"

signing_dump="$(LC_ALL=C keytool -printcert -jarfile "$artifact")"
actual_upload_sha256="$(sed -n 's/^[[:space:]]*SHA256: //p' <<<"$signing_dump" | head -1)"
if [[ "$actual_upload_sha256" != "$expected_upload_sha256" ]]; then
  echo "AAB upload certificate does not match the Google Play upload key." >&2
  exit 1
fi

artifact_sha="$(shasum -a 256 "$artifact" | awk '{print $1}')"
cat > "$build_info" <<EOF
artifact=$(basename "$artifact")
version=$version_name
build_number=$build_number
git_commit=$git_sha
git_branch=$git_branch
sha256=$artifact_sha
upload_certificate_sha256=$actual_upload_sha256
launcher_icon_sha256=$launcher_icon_sha
built_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
release_markers=profile-invite-action,public-parking-details-photo-gallery,public-parking-reviews-count,public-parking-photos-count,public-parking-details-scroll-view,deep-link-cold-start-v1,referral-deferred-recovery-v3,referral-link-fallback-v1,referral-link-capture-v2,referral-device-identity-v1
EOF

printf 'AAB: %s\n' "$artifact"
printf 'Build info: %s\n' "$build_info"
printf 'SHA-256: %s\n' "$artifact_sha"
