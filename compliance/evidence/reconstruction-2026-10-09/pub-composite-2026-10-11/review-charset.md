# Exact-source review: four charset Pub packages

Reviewed 2026-10-11. Technical source/licence-evidence review only; no legal clearance or release approval. No canonical repository files or Git state were changed. Paths below are relative to `acquired/<package>/source/` unless otherwise stated. The acquisition directory is `C:/Users/Oluwa/Documents/ChatGPT/Web Apps/work/ola-pub-composite-evidence-20261011/`.

## Recommendation

| Package | Exact version | Recommended concluded SPDX | Technical evidence status | Scope |
|---|---|---|---|---|
| flutter_charset_detector | 1.0.2 | NOASSERTION for whole archive; MPL-2.0 supported for `lib/flutter_charset_detector.dart` | Needs Verification | The library wrapper is mapped by the root notice; bundled example scripts, generated files and example text/assets have incomplete provenance for an exhaustive archive-level conclusion. |
| flutter_charset_detector_android | 1.0.0 | MPL-2.0 | Verified with conditions | This Pub archive's wrapper/build source only; excludes separately fetched juniversalchardet, Kotlin, Flutter and other native/build dependencies. |
| flutter_charset_detector_ios | 1.0.2 | MPL-2.0 | Verified with conditions | This Pub archive's Dart/Swift/Objective-C wrapper source and supporting files only; excludes UniversalDetector2/uchardet and Flutter. |
| flutter_charset_detector_platform_interface | 1.1.0 | MPL-2.0 | Verified with conditions | This Pub archive's Dart interface/method-channel source and supporting files only; excludes Flutter and plugin_platform_interface. |

The last three conclusions use the shared root LICENSE as the directory-level notice for the `flutter_charset_detector` plugin family, corroborated by each archive's package identity and implementation descriptions. They are evidence conclusions for the hosted Pub package source, not the combined platform executable. If the inventory field is intended to describe a package plus all resolved native dependencies, these MPL-2.0 values must not be used for that wider scope; retain NOASSERTION until that separate component inventory is reviewed.

## Identity and verification

| Package | Archive SHA-256 | Inventoried files |
|---|---|---|
| flutter_charset_detector 1.0.2 | edc87079f3c8917f2fa5620e594d10deef81bbf3d7a89cf99441dec955a06d9f | 75 |
| flutter_charset_detector_android 1.0.0 | 2439a3bf418fe0fb962fc3dc9d0401c3561a497017bc587b9c48a47490f9c428 | 13 |
| flutter_charset_detector_ios 1.0.2 | e0e2c7b819cd1f7c9a50da94bf7f0e6d7a095eb64e81196ec758e77793903d43 | 10 |
| flutter_charset_detector_platform_interface 1.1.0 | 1c09ed7b314a5a9dde76057b98b7d35458ba881eed03d5e5b6f7f74b4869d18c | 8 |

Independently recomputed each stored archive's SHA-256 and every inventoried extracted file's SHA-256: all matched the supplied acquisition inventories, with zero mismatches across 106 files. Forced recursive file counts also match. The parent review acquired these releases and matched them to the current locked inventory; this subreview did not separately reread the canonical lockfile.

Each `release.json` identifies the exact Pub version and archive URL. Each `pubspec.yaml:1-4` confirms name/version and gives `https://github.com/amake/flutter_charset_detector` as homepage. None of these pubspecs has a licence-expression field. The inventory's Git commit and Git tag are null. A repository homepage is not an authenticated archive-to-tag mapping. No current GitHub HEAD, inferred version tag, native source archive or resolved CocoaPods tree was substituted for these release bytes.

## Shared composite notice

Every archive's complete `LICENSE` is identical: 42,634 bytes, SHA-256 `47aa01302693c2ab65f56c90c500f43d5fb4ddda5a4ced1cd102254df3865eb3`, 850 lines. It is the only filename identified as a LICENSE/NOTICE/COPYING/LEGAL document in each inventory.

The complete text and relevant source/build files were read. The scope labels are material:

- `LICENSE:1-4`: `flutter_charset_detector` and `UniversalDetector`, followed by Mozilla Public License Version 2.0.
- `LICENSE:358-370`: MPL 2.0 Exhibit A and its allowance for a notice in a relevant LICENSE directory file. This supports treating the root document as the wrapper-source notice despite absent per-file headers.
- `LICENSE:372-376`: the standard Exhibit B template, inside the complete licence text. Its presence alone is not a separately applied incompatibility notice and does not establish MPL-2.0-no-copyleft-exception.
- `LICENSE:378-383`: separator, `juniversalchardet` and `uchardet`, followed by Mozilla Public License Version 1.1.
- `LICENSE:808-845`: standard MPL 1.1 multiple-licensing clause and unfilled Exhibit A template. The original-code, developer, contributor, copyright and alternative-licence blanks remain unfilled. This supplies no concrete alternative grant and cannot support an OR expression.

Therefore `MPL-2.0 OR MPL-1.1` is unsupported. Automatically applying `MPL-2.0 AND MPL-1.1` to each Pub wrapper archive is also unsupported: the MPL 1.1 section is expressly labelled for native libraries whose implementation bytes are absent from these archives. Preserve the entire upstream composite LICENSE in evidence/notice handling while separately recording source scopes. Do not silently reduce the upstream notice document to only the wrapper section.

No populated copyright-owner/year notice was found in the wrapper source or root document. A forced text search across every archive found no additional copyright/licence header beyond the items discussed here. `flutter_charset_detector_ios/ios/flutter_charset_detector_ios.podspec:15` contains placeholder author data (`Your Company`, `email@example.com`), which is not reliable attribution. The MPL 1.1 Exhibit A copyright blanks are templates, not identified rights holders. Missing attribution must remain explicit; do not invent a copyright holder from the repository account, author metadata or package name.

## Package details

### flutter_charset_detector 1.0.2

`lib/flutter_charset_detector.dart:1-16` is a small Dart facade: platform-interface imports/exports at lines 4-7 and delegation at lines 9-15. No embedded detection implementation is present. `pubspec.yaml:10-21` declares the three federated Pub dependencies; lines 29-35 endorse Android and iOS packages. `CHANGELOG.md:1-3` identifies the federated migration.

`README.md:9-17` describes UniversalDetector2/uchardet for iOS and juniversalchardet for Android. Those descriptions are native dependency leads, not exact native licence conclusions. `README.md:29-30` links particular upstream documentation versions, which likewise does not authenticate the application's resolved native artifacts.

The archive additionally ships `test/` and a full `example/` tree, including platform templates/scripts, generated files, PNG assets and `example/assets/sjis-example.txt`. The Shift-JIS file is 284 bytes (SHA-256 `3bf679d4a93704765050c124c5f25f338a359e6c029791245454973171fd1e39`), contains a descriptive Japanese paragraph ending in `[1]`, and has no attribution or source reference. `example/README.md:7-16` explains its encoding and use, not its provenance or licence. No particular third-party source or licence for that paragraph is asserted here.

`example/android/gradlew:3-7` and `example/android/gradlew.bat:2-6` identify Gradle startup scripts; neither file contains a licence/copyright header. They invoke a wrapper JAR at `gradlew:63,160` / `gradlew.bat:72-75`, but no wrapper JAR is in this archive. `example/android/gradle/wrapper/gradle-wrapper.properties:6` references an external Gradle 7.0.2 distribution. The files' upstream provenance/licensing was not independently resolved, so no Apache grant is inferred.

`example/ios/Flutter/Flutter.podspec:2-3` calls itself generated; lines 7-13 declare an external Flutter component, including MIT metadata; lines 15-17 explain it is a placeholder with `path/to/nothing` rather than a bundled framework. This is neither a grant for the whole charset archive nor proof that its generated podspec source is independently MIT-licensed. `example/ios/Runner/GeneratedPluginRegistrant.h:1-3` and `.m:1-3` also identify generated files without licence headers. PNG asset provenance is not identified in archive notices.

`example/ios/Podfile.lock:3-6` records UniversalDetector2 2.0.0 in the published example. This is historical example evidence, not proof of the consuming app's dependency version; the reviewed iOS package now expressly requires 2.0.1. No CocoaPods remediation or resolution was performed.

Decision: support MPL-2.0 for the runtime Dart facade; retain whole-archive NOASSERTION / Needs Verification unless the record explicitly limits itself to consumed wrapper source or evidence resolves the example-material scope. Do not invent a composite expression from generated dependency metadata or unverified asset provenance.

### flutter_charset_detector_android 1.0.0

Archive consists of Dart wrapper, Kotlin wrapper, build/configuration files, documentation and the shared LICENSE. `pubspec.yaml:2,24-29` explicitly identifies this as the Android implementation of the plugin family. `lib/flutter_charset_detector_android.dart:7-21` registers and invokes a method channel. `android/src/main/kotlin/com/madlonkay/flutter_charset_detector/FlutterCharsetDetectorPlugin.kt:9,37` imports and invokes the external `org.mozilla.universalchardet.UniversalDetector`; the Kotlin file's full 66 lines contain wrapper logic, not bundled detector source.

`android/build.gradle:41-43` declares Kotlin stdlib and `com.github.albfernandez:juniversalchardet:2.4.0`; lines 5,12-13 establish Kotlin 1.5.31 and Android Gradle plugin build dependencies. No Java detector source, JAR, AAR or equivalent native-library implementation is included in the 13-file archive. Root MPL 1.1 labels document the external engine family, but its exact Maven artifact and source terms were not reviewed. Recommended Pub-source expression: MPL-2.0, Verified with conditions. Actual native artifact provenance/licensing remains a separate unresolved review, including any grants beyond this copied notice.

### flutter_charset_detector_ios 1.0.2

`pubspec.yaml:2,24-28` identifies the iOS implementation of the plugin family. `ios/flutter_charset_detector_ios.podspec:14` explicitly points to the shared root LICENSE. Lines 16-18 restrict local source to `Classes/**/*` and depend on Flutter; line 25 pins UniversalDetector2 2.0.1. The podspec's version `0.0.1` at line 8 and placeholder homepage/author at lines 13,15 do not override the authenticated Pub version or establish upstream identity.

`ios/Classes/SwiftFlutterCharsetDetectorPlugin.swift:1-3,33` imports and invokes UniversalDetector2. The 52-line Swift wrapper, 15-line `.m` registration bridge and four-line `.h` are present; no UniversalDetector2 or uchardet implementation/binary is in the ten-file archive. `lib/flutter_charset_detector_ios.dart:5-19` is the Dart method-channel wrapper. Recommended Pub-source expression: MPL-2.0, Verified with conditions. Native UniversalDetector2 2.0.1/uchardet bytes and applicable source/notice requirements remain separately unresolved. The label `UniversalDetector` in the composite notice is not sufficient to certify exact UniversalDetector2 2.0.1 contents or its underlying uchardet revision.

### flutter_charset_detector_platform_interface 1.1.0

Eight-file archive: shared LICENSE, README, changelog, analysis configuration, pubspec and three Dart files. `pubspec.yaml:2` and `README.md:3-7` identify the common interface for the same plugin family. `lib/flutter_charset_detector_platform_interface.dart:4-6` imports the result/method-channel classes and external plugin_platform_interface; `lib/src/method_channel_charset_detector.dart:6-22` implements method-channel calls; `lib/decoding_result.dart:1-16` defines the result type. No native detector source, binary or native build declaration is included. `pubspec.yaml:10-13` declares Flutter and plugin_platform_interface dependencies. Recommended Pub-source expression: MPL-2.0, Verified with conditions; copied native-library notices do not establish bundled native source.

## Conditions and remaining checks

1. Retain the exact composite LICENSE and any future discovered attribution/source notices. Record wrapper and engine components separately, with no implied alternative licence choice.
2. Assess release treatment of MPL-covered wrapper files, including modified files, source availability and notice delivery, against the actual distribution. The archive text itself describes these at MPL 2.0 `LICENSE:163-207`; this review does not certify implementation of those requirements.
3. Keep native-library review unresolved until exact resolved artifacts/source and their complete notices are acquired under a separately authorized scope. No source fetching, dependency resolution, CocoaPods repair, native overrides or downstream clearance occurred in this review.
4. For the main package, resolve bundled example-material provenance or document an explicit consumed-source scope before replacing whole-archive NOASSERTION. Keep missing populated copyright attribution and unproven Git mapping visible.
5. Legal interpretation of copyleft compatibility or release permission belongs to counsel. These technical recommendations do not label MPL software prohibited or automatically approve distribution. Counsel Review Required is appropriate if release policy requires a legal decision about the actual combined distribution; it is not a substitute for the missing source evidence described above.
