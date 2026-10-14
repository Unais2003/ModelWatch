#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/ModelWatch.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/ModelWatch"
WARMUP_SECONDS="${MODELWATCH_PERF_WARMUP_SECONDS:-5}"
SAMPLE_COUNT="${MODELWATCH_PERF_SAMPLE_COUNT:-10}"
SAMPLE_INTERVAL_SECONDS="${MODELWATCH_PERF_SAMPLE_INTERVAL_SECONDS:-1}"
MEASURED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
OUTPUT_PATH="${1:-${TMPDIR:-/tmp}/ModelWatch-performance-$(date -u +"%Y%m%d-%H%M%S").json}"

validate_positive_integer() {
  local name="$1"
  local value="$2"

  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    echo "$name must be a positive integer." >&2
    exit 2
  fi
}

validate_positive_integer "MODELWATCH_PERF_WARMUP_SECONDS" "$WARMUP_SECONDS"
validate_positive_integer "MODELWATCH_PERF_SAMPLE_COUNT" "$SAMPLE_COUNT"
validate_positive_integer "MODELWATCH_PERF_SAMPLE_INTERVAL_SECONDS" "$SAMPLE_INTERVAL_SECONDS"

if [[ -e "$OUTPUT_PATH" ]]; then
  echo "Refusing to overwrite existing result: $OUTPUT_PATH" >&2
  exit 2
fi

OUTPUT_DIRECTORY="$(dirname "$OUTPUT_PATH")"
if [[ ! -d "$OUTPUT_DIRECTORY" ]]; then
  echo "Output directory does not exist: $OUTPUT_DIRECTORY" >&2
  exit 2
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ModelWatch-performance.XXXXXX")"
LAUNCH_RESULT="$WORK_DIR/launch.json"
TOP_OUTPUT="$WORK_DIR/top.txt"
APP_LOG="$WORK_DIR/app.log"
APP_PID=""

cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi

  if [[ -d "$WORK_DIR" ]]; then
    rm -R "$WORK_DIR"
  fi
}

trap cleanup EXIT INT TERM

"$ROOT_DIR/script/build_and_run.sh" --release >/dev/null

MODELWATCH_PERFORMANCE_BENCHMARK=1 \
MODELWATCH_PERFORMANCE_OUTPUT="$LAUNCH_RESULT" \
"$APP_BINARY" \
  -ApplePersistenceIgnoreState YES \
  -hasCompletedPrivacyOnboarding YES \
  -openDashboardAtLaunch YES \
  -showMenuBarStatus YES \
  >"$APP_LOG" 2>&1 &
APP_PID="$!"

attempt=0
while [[ ! -s "$LAUNCH_RESULT" ]]; do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo "ModelWatch exited before reporting launch readiness." >&2
    exit 1
  fi

  attempt=$((attempt + 1))
  if (( attempt >= 500 )); then
    echo "Timed out waiting for ModelWatch launch readiness." >&2
    exit 1
  fi

  sleep 0.02
done

LAUNCH_READY_MILLISECONDS="$(
  plutil -extract launchReadyMilliseconds raw "$LAUNCH_RESULT"
)"

sleep "$WARMUP_SECONDS"

TOP_SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
top \
  -l "$TOP_SAMPLE_COUNT" \
  -n 1 \
  -s "$SAMPLE_INTERVAL_SECONDS" \
  -pid "$APP_PID" \
  -stats pid,cpu,mem,power \
  >"$TOP_OUTPUT"

if ! kill -0 "$APP_PID" 2>/dev/null; then
  echo "ModelWatch exited before performance sampling completed." >&2
  exit 1
fi

read -r ACTUAL_SAMPLE_COUNT AVERAGE_CPU_PERCENT AVERAGE_MEMORY_MB PEAK_MEMORY_MB AVERAGE_POWER_SCORE <<<"$(
  awk -v pid="$APP_PID" '
    function memory_kb(value, unit, amount) {
      gsub(/\+/, "", value)
      unit = substr(value, length(value), 1)
      amount = value + 0
      if (unit == "G") return amount * 1024 * 1024
      if (unit == "M") return amount * 1024
      if (unit == "K") return amount
      return amount / 1024
    }

    $1 == pid {
      seen += 1
      if (seen == 1) next

      cpu = $2 ~ /^[0-9.]+$/ ? $2 : 0
      memory = memory_kb($3)
      power = $4 ~ /^[0-9.]+$/ ? $4 : 0
      count += 1
      cpu_total += cpu
      memory_total += memory
      if (memory > peak_memory) peak_memory = memory
      power_total += power
    }

    END {
      if (count == 0) exit 1
      printf "%d %.3f %.3f %.3f %.3f", count, cpu_total / count,
        memory_total / count / 1024, peak_memory / 1024, power_total / count
    }
  ' "$TOP_OUTPUT"
)"

if (( ACTUAL_SAMPLE_COUNT != SAMPLE_COUNT )); then
  echo "Expected $SAMPLE_COUNT performance samples, received $ACTUAL_SAMPLE_COUNT." >&2
  exit 1
fi

APP_VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_BUNDLE/Contents/Info.plist")"
BUILD_NUMBER="$(plutil -extract CFBundleVersion raw "$APP_BUNDLE/Contents/Info.plist")"
MACOS_VERSION="$(sw_vers -productVersion)"
HARDWARE_MODEL="$(sysctl -n hw.model)"

cat >"$OUTPUT_PATH" <<JSON
{
  "schemaVersion": 1,
  "measuredAt": "$MEASURED_AT",
  "appVersion": "$APP_VERSION",
  "buildNumber": "$BUILD_NUMBER",
  "configuration": "release",
  "environment": {
    "macOSVersion": "$MACOS_VERSION",
    "hardwareModel": "$HARDWARE_MODEL",
    "isolatedData": true
  },
  "launchReadyMilliseconds": $LAUNCH_READY_MILLISECONDS,
  "idle": {
    "warmupSeconds": $WARMUP_SECONDS,
    "sampleIntervalSeconds": $SAMPLE_INTERVAL_SECONDS,
    "sampleCount": $ACTUAL_SAMPLE_COUNT,
    "averageCPUPercent": $AVERAGE_CPU_PERCENT,
    "averageResidentMemoryMB": $AVERAGE_MEMORY_MB,
    "peakResidentMemoryMB": $PEAK_MEMORY_MB,
    "averageRelativePowerScore": $AVERAGE_POWER_SCORE
  }
}
JSON

plutil -extract schemaVersion raw "$OUTPUT_PATH" >/dev/null
echo "Performance result: $OUTPUT_PATH"
cat "$OUTPUT_PATH"
