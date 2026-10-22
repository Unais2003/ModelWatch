#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
TEMPLATE="$ROOT_DIR/docs/engineering/release-validation-template.md"

usage() {
  echo "usage: $0 [output-path]" >&2
}

fail() {
  echo "error: $1" >&2
  exit 1
}

if (( $# > 1 )); then
  usage
  exit 2
fi

[[ -f "$INFO_PLIST" ]] || fail "missing source Info.plist"
[[ -f "$TEMPLATE" ]] || fail "missing release validation template"

VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST")"
BUILD_NUMBER="$(plutil -extract CFBundleVersion raw "$INFO_PLIST")"
COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD)"
SHORT_COMMIT="${COMMIT:0:12}"
CREATED_DATE="$(date +%F)"

DEFAULT_OUTPUT="$ROOT_DIR/dist/validation/ModelWatch-$VERSION-$BUILD_NUMBER-$SHORT_COMMIT-validation.md"
OUTPUT_PATH="${1:-$DEFAULT_OUTPUT}"
if [[ "$OUTPUT_PATH" != /* ]]; then
  OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH"
fi

[[ ! -e "$OUTPUT_PATH" ]] || fail "validation record already exists: $OUTPUT_PATH"

OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
mkdir -p "$OUTPUT_DIR"

TEMP_PATH="$(mktemp "$OUTPUT_DIR/.ModelWatch-validation.XXXXXX")"
cleanup() {
  if [[ -f "$TEMP_PATH" ]]; then
    rm -f "$TEMP_PATH"
  fi
}
trap cleanup EXIT INT TERM

awk \
  -v version="$VERSION" \
  -v build="$BUILD_NUMBER" \
  -v commit="$COMMIT" \
  -v created_date="$CREATED_DATE" \
  '{
    gsub(/\{\{VERSION\}\}/, version)
    gsub(/\{\{BUILD\}\}/, build)
    gsub(/\{\{COMMIT\}\}/, commit)
    gsub(/\{\{DATE\}\}/, created_date)
    print
  }' "$TEMPLATE" >"$TEMP_PATH"

mv "$TEMP_PATH" "$OUTPUT_PATH"
trap - EXIT INT TERM

echo "Created release validation record: $OUTPUT_PATH"
echo "Complete it against the exact signed and notarized candidate before distribution."
