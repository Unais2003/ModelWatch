#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/ModelWatch.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/ModelWatch"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
APP_ICON="$APP_BUNDLE/Contents/Resources/AppIcon.icns"

require_file() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    echo "Missing release artifact: $path" >&2
    exit 1
  fi
}

"$ROOT_DIR/script/package_release.sh" --validate
swift test --package-path "$ROOT_DIR"
"$ROOT_DIR/script/build_and_run.sh" --verify

require_file "$APP_BINARY"
require_file "$INFO_PLIST"
require_file "$APP_ICON"

[[ -x "$APP_BINARY" ]] || {
  echo "Release executable is not executable: $APP_BINARY" >&2
  exit 1
}

plutil -lint "$INFO_PLIST" >/dev/null
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

BUNDLE_IDENTIFIER="$(plutil -extract CFBundleIdentifier raw "$INFO_PLIST")"
MARKETING_VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST")"
BUILD_NUMBER="$(plutil -extract CFBundleVersion raw "$INFO_PLIST")"

[[ "$BUNDLE_IDENTIFIER" == "com.modelwatch.app" ]] || {
  echo "Unexpected bundle identifier: $BUNDLE_IDENTIFIER" >&2
  exit 1
}

echo "Release-candidate preflight passed for ModelWatch $MARKETING_VERSION ($BUILD_NUMBER)."
echo "Manual accessibility, appearance, activity lifecycle, and signed-build checks remain required."
