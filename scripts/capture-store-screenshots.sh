#!/bin/bash

set -euo pipefail

shots_udid="${SHOTS_UDID:-B49AE61E-137F-4710-9E4A-E7080591BD0E}"
shots_bundle_id="dev.aftaab.kindling"
shots_output_dir="screenshots/raw/en-US/iPhone_17_Pro_Max_-_Deep_Blue_-_Portrait"
shots_app_path=".build/DerivedData/Build/Products/Debug-iphonesimulator/Kindling.app"
xcrun simctl boot "$shots_udid" 2>/dev/null || true

xcodebuild \
  -project ios/Kindling.xcodeproj \
  -scheme Kindling \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$shots_udid" \
  -derivedDataPath .build/DerivedData \
  build

xcrun simctl uninstall "$shots_udid" "$shots_bundle_id" 2>/dev/null || true
xcrun simctl install "$shots_udid" "$shots_app_path"
xcrun simctl status_bar "$shots_udid" override \
  --time 9:41 \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4

mkdir -p "$shots_output_dir"

capture_screen() {
  local screen_name="$1"
  local output_name="$2"

  xcrun simctl terminate "$shots_udid" "$shots_bundle_id" 2>/dev/null || true
  SIMCTL_CHILD_KINDLING_SCREEN="$screen_name" \
    xcrun simctl launch "$shots_udid" "$shots_bundle_id"
  # Fresh simulator launches can spend several seconds initializing SwiftData
  # and StoreKit. Wait for the deterministic debug route to settle before the
  # capture so each file depicts the requested screen, not the previous one.
  sleep 8
  xcrun simctl io "$shots_udid" screenshot \
    "$shots_output_dir/$output_name.png"
}

capture_screen draft 01-remember
capture_screen atlas 02-atlas
capture_screen trail 03-memory-trail
capture_screen moment 04-find-it
capture_screen share 05-share-safely

echo "Captured five seeded memory-product screens in $shots_output_dir"
