#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="/private/tmp/TableViewControllerCoverKitRecordDemos"
APP_DIR="$BUILD_DIR/Demo.app"
BUNDLE_ID="dev.tableviewcontrollercoverkit.recorddemo"
DEVICE_ID="${DEVICE_ID:-}"
BUILD_ONLY=0

if [[ "${1:-}" == "--build-only" ]]; then
  BUILD_ONLY=1
fi

mkdir -p "$APP_DIR" "$BUILD_DIR/modulecache" "$BUILD_DIR/recordings"
cp "$SCRIPT_DIR/Info.plist" "$APP_DIR/Info.plist"

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-ios15.0-simulator"

xcrun swiftc \
  -parse-as-library \
  -target "$TARGET" \
  -sdk "$SDK" \
  -module-cache-path "$BUILD_DIR/modulecache" \
  -O \
  "$SCRIPT_DIR/RecordDemoApp.swift" \
  "$REPO_ROOT/Sources/TableViewControllerCoverKit/CoverImageTableViewController.swift" \
  -o "$APP_DIR/Demo"

codesign --force --sign - "$APP_DIR" >/dev/null

xcrun swiftc \
  -module-cache-path "$BUILD_DIR/modulecache" \
  "$SCRIPT_DIR/VideoToGif.swift" \
  -o "$BUILD_DIR/video_to_gif"

if [[ "$BUILD_ONLY" == "1" ]]; then
  echo "Build succeeded."
  exit 0
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ { print $2; exit }')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No booted simulator found. Boot one in Simulator.app, or set DEVICE_ID=<udid>." >&2
  exit 1
fi

xcrun simctl install "$DEVICE_ID" "$APP_DIR"

record_demo() {
  local name="$1"
  local gif_path="$2"
  shift 2

  local mp4_path="$BUILD_DIR/recordings/$name.mp4"
  rm -f "$mp4_path"

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl io "$DEVICE_ID" recordVideo --codec h264 "$mp4_path" &
  local recorder_pid=$!

  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" "$@"
  sleep 10

  kill -INT "$recorder_pid"
  wait "$recorder_pid" || true

  "$BUILD_DIR/video_to_gif" "$mp4_path" "$gif_path" 3.0
}

record_demo "demo-default" "$REPO_ROOT/Docs/demo-default.gif"
record_demo "demo-large-title" "$REPO_ROOT/Docs/demo-large-title.gif" --large-title

echo "Updated Docs/demo-default.gif and Docs/demo-large-title.gif."
