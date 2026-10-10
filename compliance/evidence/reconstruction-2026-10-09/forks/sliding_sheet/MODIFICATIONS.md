# sliding_sheet 0.5.2: source comparison and modification record

Recorded 2026-10-09; comparison target is immutable source identity in manifest.json.
Custom bottom-sheet sizing, keyboard-aware dismissal, context fallback, visual transition/backdrop and layout handling; reMeasure controller support; optional scrollbar; current Flutter binding/MediaQuery APIs. README differs. Full patch is authoritative; example app tree is omitted from vendored distribution.

Baseline kind: published-archive. Upstream Git commit: None; archive digest: c8607c47c9bb1779010e05f3625bfa9fcc5bb9eb5a93ec40e630e27de67c20ab.
Target commit: cd354dbf3d264c8b725c474611da2d5d7002d415; canonical path: budget/packages/sliding_sheet-0.5.2-modified.
This records inherited modifications; it does not claim these changes were authored by ÓLA or made on this record date. Git authors/dates are retained in commits.txt or vendoring-history.txt.
For published archives, this is an authenticated versioned release comparison, not proof of a historical Git fork point. The historical upstream Git base is unavailable and is not inferred.

Raw change counts: {"added": 0, "modified": 5, "line-endings-only": 8, "deleted": 54}. Raw CRLF differences are retained in the complete binary-capable patch; separate line-ending-only labels avoid describing them as code changes. All omitted example files, including binaries, are listed in delta.json; no omitted files are silently excluded.

Licence and headers: MIT root licence is unchanged after CRLF normalization. Raw bytes/digests are retained on both sides. Licence/notice-path differences: ['LICENSE']. Copyright/SPDX/licensed-under statements in retained source files are recorded in header-review.json and preserved. Files absent on the target side are disclosed in the full delta, not claimed retained.

Technical obligations to carry into release review:
- Preserve original copyright and MIT permission text in copies/substantial portions, including modified distributions.
- Retain this source/delta record and avoid reattributing upstream or inherited author work to ÓLA.
- MIT text permits modification; this is technical evidence of the retained grant, not final legal clearance. This record does not assert MIT alone requires publication of all modified source.
- Include exact source revisions/archives and complete patches in release-specific source mapping as applicable to the overall application; assess combined distribution/GPL/store obligations separately with qualified counsel.
- This is a central modification record, not evidence that final binaries, bundled notices or Corresponding Source delivery have been verified.

Files changed (complete classifications):
- line-endings-only: `CHANGELOG.md`
- line-endings-only: `LICENSE`
- modified: `README.md`
- line-endings-only: `analysis_options.yaml`
- deleted: `example/android/app/build.gradle`
- deleted: `example/android/app/src/debug/AndroidManifest.xml`
- deleted: `example/android/app/src/main/AndroidManifest.xml`
- deleted: `example/android/app/src/main/kotlin/com/example/example/MainActivity.kt`
- deleted: `example/android/app/src/main/res/drawable/launch_background.xml`
- deleted: `example/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- deleted: `example/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- deleted: `example/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- deleted: `example/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- deleted: `example/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- deleted: `example/android/app/src/main/res/values/styles.xml`
- deleted: `example/android/app/src/profile/AndroidManifest.xml`
- deleted: `example/android/build.gradle`
- deleted: `example/android/gradle.properties`
- deleted: `example/android/gradle/wrapper/gradle-wrapper.properties`
- deleted: `example/android/settings.gradle`
- deleted: `example/assets/maps_screenshot.png`
- deleted: `example/ios/Flutter/AppFrameworkInfo.plist`
- deleted: `example/ios/Flutter/Debug.xcconfig`
- deleted: `example/ios/Flutter/Release.xcconfig`
- deleted: `example/ios/Runner.xcodeproj/project.pbxproj`
- deleted: `example/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- deleted: `example/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- deleted: `example/ios/Runner.xcworkspace/contents.xcworkspacedata`
- deleted: `example/ios/Runner/AppDelegate.swift`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`
- deleted: `example/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- deleted: `example/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- deleted: `example/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- deleted: `example/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
- deleted: `example/ios/Runner/Base.lproj/LaunchScreen.storyboard`
- deleted: `example/ios/Runner/Base.lproj/Main.storyboard`
- deleted: `example/ios/Runner/Info.plist`
- deleted: `example/ios/Runner/Runner-Bridging-Header.h`
- deleted: `example/lib/main.dart`
- deleted: `example/lib/util/custom_container.dart`
- deleted: `example/lib/util/util.dart`
- deleted: `example/pubspec.yaml`
- line-endings-only: `lib/sliding_sheet.dart`
- line-endings-only: `lib/src/scrolling.dart`
- modified: `lib/src/sheet.dart`
- line-endings-only: `lib/src/sheet_container.dart`
- modified: `lib/src/sheet_dialog.dart`
- line-endings-only: `lib/src/sheet_listener_builder.dart`
- modified: `lib/src/specs.dart`
- modified: `lib/src/util.dart`
- line-endings-only: `pubspec.yaml`
