#!/usr/bin/env bash
# Installs the app on a simulator and captures screenshots of key screens.
# Usage: screenshots.sh <simulator-udid> <path/to/ReadKeeper.app> <output-dir>
set -euo pipefail

UDID="$1"
APP="$2"
OUT="$3"
mkdir -p "$OUT"

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
xcrun simctl install "$UDID" "$APP"

shoot() {
  local name="$1"
  shift
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "Saved $name.png"
}

xcrun simctl ui "$UDID" appearance light
shoot 01-shelf-demo   -RKDemoShelf YES -RKStartTab shelf
shoot 02-shelf-empty  -RKStartTab shelf
shoot 03-library      -RKStartTab library
shoot 04-stats        -RKStartTab stats
shoot 05-settings     -RKStartTab settings

xcrun simctl ui "$UDID" appearance dark
shoot 06-shelf-demo-dark  -RKDemoShelf YES -RKStartTab shelf
shoot 07-shelf-empty-dark -RKStartTab shelf
xcrun simctl ui "$UDID" appearance light

# A short screen recording of the demo shelf (scrolling is added in later milestones).
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/shelf-demo.mp4" &
REC_PID=$!
sleep 1
xcrun simctl launch "$UDID" "$BUNDLE_ID" -RKDemoShelf YES -RKStartTab shelf >/dev/null
sleep 6
kill -INT "$REC_PID"
wait "$REC_PID" 2>/dev/null || true
echo "Saved shelf-demo.mp4"
