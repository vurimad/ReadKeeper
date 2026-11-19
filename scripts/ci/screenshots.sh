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

# shoot <name> [launch args...]   (set WAIT=<seconds> to wait longer, e.g. for network)
shoot() {
  local name="$1"
  shift
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@" >/dev/null
  sleep "${WAIT:-5}"
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "Saved $name.png"
}

xcrun simctl ui "$UDID" appearance light
shoot 01-shelf-demo      -RKDemoShelf YES -RKStartTab shelf
shoot 02-shelf-empty     -RKInMemory YES -RKStartTab shelf
shoot 03-library-demo    -RKDemoShelf YES -RKStartTab library
shoot 04-library-empty   -RKInMemory YES -RKStartTab library
WAIT=12 shoot 05-add-search -RKInMemory YES -RKStartTab shelf -RKOpenAdd YES -RKSearchQuery "pride and prejudice"
shoot 06-settings        -RKInMemory YES -RKStartTab settings
shoot 09-book-detail     -RKDemoShelf YES -RKStartTab shelf -RKOpenBook "Pride and Prejudice"
shoot 10-book-finished   -RKDemoShelf YES -RKStartTab shelf -RKOpenBook "Jane Eyre"
shoot 11-log-progress    -RKDemoShelf YES -RKStartTab shelf -RKOpenBook "Pride and Prejudice" -RKOpenLog YES
shoot 12-log-audiobook   -RKDemoShelf YES -RKStartTab shelf -RKOpenBook "Moby-Dick" -RKOpenLog YES
shoot 13-stats-demo      -RKDemoShelf YES -RKStartTab stats
shoot 14-stats-empty     -RKInMemory YES -RKStartTab stats

xcrun simctl ui "$UDID" appearance dark
shoot 07-shelf-demo-dark   -RKDemoShelf YES -RKStartTab shelf
shoot 08-library-demo-dark -RKDemoShelf YES -RKStartTab library
shoot 15-stats-demo-dark   -RKDemoShelf YES -RKStartTab stats
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
