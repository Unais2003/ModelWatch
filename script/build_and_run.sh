#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ModelWatch"
BUILD_CONFIGURATION="debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SOURCE_INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
SOURCE_ICON="$ROOT_DIR/Resources/AppIcon.png"
BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw "$SOURCE_INFO_PLIST")"

usage() {
  echo "usage: $0 [build|run|--debug|--logs|--telemetry|--verify|--release]" >&2
}

case "$MODE" in
  build|run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--release|release)
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ "$MODE" == "release" || "$MODE" == "--release" ||
      "$MODE" == "verify" || "$MODE" == "--verify" ]]; then
  BUILD_CONFIGURATION="release"
fi

swift build -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)/$APP_NAME"

mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$SOURCE_INFO_PLIST" "$INFO_PLIST"

ICON_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ModelWatch-icon.XXXXXX")"
ICONSET_DIR="$ICON_WORK_DIR/AppIcon.iconset"

cleanup_icon_work_dir() {
  if [[ -d "$ICON_WORK_DIR" ]]; then
    rm -R "$ICON_WORK_DIR"
  fi
}

trap cleanup_icon_work_dir EXIT
mkdir -p "$ICONSET_DIR"

create_icon() {
  local points="$1"
  local pixels="$2"
  local suffix="$3"
  sips -z "$pixels" "$pixels" "$SOURCE_ICON" \
    --out "$ICONSET_DIR/icon_${points}x${points}${suffix}.png" >/dev/null
}

create_icon 16 16 ""
create_icon 16 32 "@2x"
create_icon 32 32 ""
create_icon 32 64 "@2x"
create_icon 128 128 ""
create_icon 128 256 "@2x"
create_icon 256 256 ""
create_icon 256 512 "@2x"
create_icon 512 512 ""
create_icon 512 1024 "@2x"

iconutil -c icns "$ICONSET_DIR" -o "$APP_RESOURCES/AppIcon.icns"
cleanup_icon_work_dir
trap - EXIT

plutil -lint "$INFO_PLIST" >/dev/null
codesign --force --sign - --timestamp=none "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "Built $APP_BUNDLE ($BUILD_CONFIGURATION, ad-hoc signed)"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  build)
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    VERIFY_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ModelWatch-verify.XXXXXX")"
    VERIFY_RESULT="$VERIFY_WORK_DIR/launch.json"
    VERIFY_LOG="$VERIFY_WORK_DIR/app.log"
    VERIFY_PID=""

    cleanup_verification() {
      if [[ -n "$VERIFY_PID" ]] && kill -0 "$VERIFY_PID" 2>/dev/null; then
        kill "$VERIFY_PID" 2>/dev/null || true
        wait "$VERIFY_PID" 2>/dev/null || true
      fi

      if [[ -d "$VERIFY_WORK_DIR" ]]; then
        rm -R "$VERIFY_WORK_DIR"
      fi
    }

    trap cleanup_verification EXIT INT TERM

    MODELWATCH_PERFORMANCE_BENCHMARK=1 \
    MODELWATCH_PERFORMANCE_OUTPUT="$VERIFY_RESULT" \
    "$APP_BINARY" \
      -ApplePersistenceIgnoreState YES \
      -hasCompletedPrivacyOnboarding YES \
      -openDashboardAtLaunch YES \
      -showMenuBarStatus NO \
      >"$VERIFY_LOG" 2>&1 &
    VERIFY_PID="$!"

    attempt=0
    while [[ ! -s "$VERIFY_RESULT" ]]; do
      if ! kill -0 "$VERIFY_PID" 2>/dev/null; then
        echo "ModelWatch exited during launch verification." >&2
        sed -n '1,120p' "$VERIFY_LOG" >&2
        exit 1
      fi

      attempt=$((attempt + 1))
      if (( attempt >= 500 )); then
        echo "Timed out waiting for ModelWatch launch verification." >&2
        exit 1
      fi

      sleep 0.02
    done

    plutil -extract schemaVersion raw "$VERIFY_RESULT" >/dev/null
    echo "Verified isolated launch for $APP_BUNDLE"
    ;;
  --release|release)
    ;;
esac
