#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

MODE="${1:-release}"
APP_NAME="ModelWatch"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
SOURCE_ICON="$ROOT_DIR/Resources/AppIcon.png"
BUILT_APP="$ROOT_DIR/dist/$APP_NAME.app"
RELEASE_DIR="$ROOT_DIR/dist/releases"
SIGNING_IDENTITY="${MODELWATCH_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${MODELWATCH_NOTARY_PROFILE:-}"

usage() {
  echo "usage: $0 [release|--validate]" >&2
}

if (( $# > 1 )); then
  usage
  exit 2
fi

fail() {
  echo "error: $1" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "required command is unavailable: $command_name"
  fi
}

read_plist_value() {
  local key="$1"

  plutil -extract "$key" raw "$SOURCE_INFO_PLIST"
}

validate_project() {
  local required_command
  local bundle_identifier
  local marketing_version
  local build_number

  for required_command in swift plutil codesign ditto xcrun spctl security shasum git; do
    require_command "$required_command"
  done

  [[ -f "$SOURCE_INFO_PLIST" ]] || fail "missing source Info.plist"
  [[ -f "$SOURCE_ICON" ]] || fail "missing source app icon"
  [[ -x "$ROOT_DIR/script/build_and_run.sh" ]] || fail "build script is not executable"

  plutil -lint "$SOURCE_INFO_PLIST" >/dev/null
  xcrun --find notarytool >/dev/null
  xcrun --find stapler >/dev/null

  bundle_identifier="$(read_plist_value CFBundleIdentifier)"
  marketing_version="$(read_plist_value CFBundleShortVersionString)"
  build_number="$(read_plist_value CFBundleVersion)"

  [[ "$bundle_identifier" =~ ^[A-Za-z0-9][A-Za-z0-9.-]+$ ]] || \
    fail "CFBundleIdentifier is invalid"
  [[ "$marketing_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || \
    fail "CFBundleShortVersionString must use numeric dot-separated components"
  [[ "$build_number" =~ ^[1-9][0-9]*$ ]] || \
    fail "CFBundleVersion must be a positive integer"

  echo "Release configuration is valid for $bundle_identifier $marketing_version ($build_number)."
}

validate_release_credentials() {
  local available_identities

  [[ -n "$SIGNING_IDENTITY" ]] || \
    fail "set MODELWATCH_SIGNING_IDENTITY to a Developer ID Application identity"
  [[ "$SIGNING_IDENTITY" == "Developer ID Application:"* ]] || \
    fail "MODELWATCH_SIGNING_IDENTITY must be a Developer ID Application identity"
  [[ -n "$NOTARY_PROFILE" ]] || \
    fail "set MODELWATCH_NOTARY_PROFILE to a notarytool Keychain profile"

  available_identities="$(security find-identity -v -p codesigning)"
  if [[ "$available_identities" != *"\"$SIGNING_IDENTITY\""* ]]; then
    fail "the requested signing identity is not available in the Keychain"
  fi
}

validate_clean_checkout() {
  if ! git -C "$ROOT_DIR" diff --quiet || \
     ! git -C "$ROOT_DIR" diff --cached --quiet || \
     [[ -n "$(git -C "$ROOT_DIR" ls-files --others --exclude-standard)" ]]; then
    fail "release packaging requires a clean Git checkout"
  fi
}

case "$MODE" in
  release)
    ;;
  --validate|validate)
    validate_project
    echo "A full release also requires Apple team signing and notarization credentials."
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

validate_project
validate_release_credentials
validate_clean_checkout

MARKETING_VERSION="$(read_plist_value CFBundleShortVersionString)"
BUILD_NUMBER="$(read_plist_value CFBundleVersion)"
ARCHIVE_NAME="$APP_NAME-$MARKETING_VERSION-$BUILD_NUMBER.zip"
CHECKSUM_NAME="$ARCHIVE_NAME.sha256"
OUTPUT_ARCHIVE="$RELEASE_DIR/$ARCHIVE_NAME"
OUTPUT_CHECKSUM="$RELEASE_DIR/$CHECKSUM_NAME"

mkdir -p "$RELEASE_DIR"

[[ ! -e "$OUTPUT_ARCHIVE" ]] || fail "release archive already exists: $OUTPUT_ARCHIVE"
[[ ! -e "$OUTPUT_CHECKSUM" ]] || fail "release checksum already exists: $OUTPUT_CHECKSUM"

WORK_DIR="$(mktemp -d "$RELEASE_DIR/.ModelWatch-release.XXXXXX")"
WORK_APP="$WORK_DIR/$APP_NAME.app"
SUBMISSION_ARCHIVE="$WORK_DIR/notary-submission.zip"
FINAL_ARCHIVE="$WORK_DIR/$ARCHIVE_NAME"
FINAL_CHECKSUM="$WORK_DIR/$CHECKSUM_NAME"

cleanup() {
  if [[ -d "$WORK_DIR" ]]; then
    rm -R "$WORK_DIR"
  fi
}

trap cleanup EXIT INT TERM

"$ROOT_DIR/script/build_and_run.sh" --release
ditto "$BUILT_APP" "$WORK_APP"

codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$WORK_APP"

codesign --verify --deep --strict --verbose=2 "$WORK_APP"

if ! codesign -d --verbose=4 "$WORK_APP" 2>&1 | grep -Eq "flags=.*runtime"; then
  fail "signed application does not contain the hardened runtime flag"
fi

ditto -c -k --keepParent --sequesterRsrc "$WORK_APP" "$SUBMISSION_ARCHIVE"

xcrun notarytool submit \
  "$SUBMISSION_ARCHIVE" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$WORK_APP"
xcrun stapler validate "$WORK_APP"
codesign --verify --deep --strict --verbose=2 "$WORK_APP"
spctl --assess --type execute --verbose=2 "$WORK_APP"

ditto -c -k --keepParent --sequesterRsrc "$WORK_APP" "$FINAL_ARCHIVE"

CHECKSUM="$(shasum -a 256 "$FINAL_ARCHIVE" | awk '{print $1}')"
printf '%s  %s\n' "$CHECKSUM" "$ARCHIVE_NAME" >"$FINAL_CHECKSUM"

mv "$FINAL_ARCHIVE" "$OUTPUT_ARCHIVE"
mv "$FINAL_CHECKSUM" "$OUTPUT_CHECKSUM"

echo "Release archive: $OUTPUT_ARCHIVE"
echo "SHA-256 checksum: $OUTPUT_CHECKSUM"
