#!/bin/bash

set -euo pipefail

shots_udid="${SHOTS_UDID:-B49AE61E-137F-4710-9E4A-E7080591BD0E}"
shots_bundle_id="dev.aftaab.kindling"
shots_output_dir="screenshots/raw/en-US/iPhone_17_Pro_Max_-_Deep_Blue_-_Portrait"
shots_app_path=".build/DerivedData/Build/Products/Debug-iphonesimulator/Kindling.app"
shots_task="reply to the email"

xcrun simctl boot "$shots_udid" 2>/dev/null || true

xcodebuild \
  -project ios/Kindling.xcodeproj \
  -scheme Kindling \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$shots_udid" \
  -derivedDataPath .build/DerivedData \
  build

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
    SIMCTL_CHILD_KINDLING_TASK="$shots_task" \
    xcrun simctl launch "$shots_udid" "$shots_bundle_id"
  # SwiftData, StoreKit, and the seeded flow all initialize on launch. Give the
  # final SwiftUI state time to replace the launch surface before capture.
  sleep 3
  xcrun simctl io "$shots_udid" screenshot \
    "$shots_output_dir/$output_name.png"
}

capture_screen taskEntry 01-name-it
capture_screen firstStep 02-start-small
capture_screen session 03-two-minutes
capture_screen success 04-starting-counts
capture_screen outcome 05-no-guilt

echo "Captured five seeded app screens in $shots_output_dir"
