#!/bin/sh
# TEMPORARY DEV ASSET — NOT APPROVED FOR PUBLIC RELEASE
# Requires the existing Flutter/CocoaPods debug setup on macOS. No release arguments accepted.
set -eu
if [ "$#" -ne 0 ]; then
  echo "Only the fixed internal simulator debug build is supported." >&2
  exit 64
fi
cd "$(dirname "$0")/../../ios"
exec xcodebuild -workspace Runner.xcworkspace -scheme development \
  -configuration Debug-development -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -xcconfig Flutter/DevelopmentBrand.xcconfig CODE_SIGNING_ALLOWED=NO build
