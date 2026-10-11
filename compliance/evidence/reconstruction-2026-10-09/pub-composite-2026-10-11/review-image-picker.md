# Independent exact-source review: image_picker family

Review date: 2026-10-11. Technical provenance and licence classification only; no legal clearance. Canonical repository was not read or mutated by this reviewer. This report reviews the acquired Pub releases, not current GitHub main or native dependencies resolved during a build.

## Release identity and verification

All evidence paths below are relative to `C:/Users/Oluwa/Documents/ChatGPT/Web Apps/work/ola-pub-composite-evidence-20261011/acquired/`, unless stated otherwise. For example, `image_picker/source/LICENSE:1-231` denotes the exact local acquired file and inclusive line range.

| Package | Exact version | Archive SHA256 (independently recomputed) | Source files checked against inventory |
| --- | --- | --- | --- |
| image_picker | 1.1.2 | 021834d9c0c3de46bf0fe40341fa07168407f694d9b2bb18d532dc1261867f7a | 120; zero mismatches |
| image_picker_android | 0.8.8+2 | d6a6e78821086b0b737009b09363018309bbc6de3fd88cc5c26bc2bb44a4957f | 61; zero mismatches |
| image_picker_ios | 0.8.8+4 | 76ec722aeea419d03aa915c2c96bf5b47214b053899088c9abb4086ceecf97a7 | 87; zero mismatches |

The parent review acquired and matched these archives to the lockfile. This reviewer recomputed the archive and all extracted-file hashes against the accompanying inventories; it did not independently read the canonical lockfile. Release API metadata and exact archive URLs are preserved in each package's `release.json` and `inventory.json`. The repository paths declared by the archives are `https://github.com/flutter/packages/tree/main/packages/image_picker/<package>` (`image_picker/source/pubspec.yaml:4`, Android `pubspec.yaml:3`, iOS `pubspec.yaml:3`). These are mutable repository locations, not authenticated release commits. No commit or tag mapping is asserted. Pub archive identity is sufficient for this bounded review.

## Complete composite licence mapping

All three root LICENSE files are byte-identical, 231 lines, SHA256 `5be052679cb82ade21607d199dad720f03f00b8c4fb1e91629273f89fbe0fd60`. The full 231-line text was inspected; identical hashes establish the same text for the three files.

| Lines in each `source/LICENSE` | Grant / attribution | Source mapping |
| --- | --- | --- |
| 1-27 | `image_picker`; Copyright 2013 The Flutter Authors; three-condition BSD grant, including Google/contributor non-endorsement; standard disclaimer | `BSD-3-Clause` for Flutter-authored package source. Individual runtime files expressly direct readers to the BSD-style licence in LICENSE. |
| 29-206 | Heading `aFileChooser`; full Apache License Version 2.0, sections 1-9 | `Apache-2.0`. Directly mapped to the modified Android `FileUtils.java` below. In wrapper and iOS archives, this is carried umbrella third-party metadata with no corresponding source identified in the archive. |
| 208-231 | Apache application appendix, filled with Copyright 2011-2013 Paul Burke | Attribution attached to the aFileChooser grant, not an additional licence and not a BSD/Apache election. Retain with the entire composite file. |

No OR/election wording appears. Co-located grants for different contributions must not be converted into `BSD-3-Clause OR Apache-2.0`. The exact attribution in Android's source additionally names OpenIntents.org; the Paul Burke notice in the root file does not replace it.

## image_picker_android 0.8.8+2

**Technical class: Verified with conditions. Proposed package-source expression: `BSD-3-Clause AND Apache-2.0`.** This is supported by actual shipped runtime source, rather than merely aggregating licence names found in the root text.

* `image_picker_android/source/android/src/main/java/io/flutter/plugins/imagepicker/FileUtils.java:1-3` has the Flutter BSD-style header.
* The same file at lines 5-22 retains Copyright (C) 2007-2008 OpenIntents.org, an explicit Apache-2.0 grant, and the statement that the Flutter authors modified the file from `https://raw.githubusercontent.com/iPaulPro/aFileChooser/master/aFileChooser/src/com/ipaulpro/afilechooser/utils/FileUtils.java`. This is provenance asserted by the exact release; the mutable original URL is not a proven source revision.
* `FileUtils.java:40-147` contains the actual utility implementation, including `getPathFromUri` at line 54. It is not only an attribution file or an unused external dependency declaration.
* `image_picker_android/source/android/src/main/java/io/flutter/plugins/imagepicker/ImagePickerDelegate.java:117,186,204,648,681,686,703,707,733` holds, constructs, passes, and calls this utility in runtime picking flows. These references establish its integration into the plugin source.
* The remaining Java/Dart runtime source headers, e.g. `lib/image_picker_android.dart:1-3`, `lib/src/messages.g.dart:1-3`, `android/src/main/java/io/flutter/plugins/imagepicker/ImagePickerPlugin.java:1-3`, and `Messages.java:1-3`, point to BSD terms. Every `.dart`, `.java`, `.m`, `.h`, `.swift`, `.cpp`, and `.cc` file present in this archive contains the Flutter BSD-style header; FileUtils additionally retains Apache terms.

Conditions for using this technical conclusion: retain the complete root LICENSE and the source-specific OpenIntents attribution / Flutter modification notice; make the actual distribution's required licence and attribution presentation a separate verification step. This review does not prove that a final application bundles or displays those notices. No standalone NOTICE file, vendored JAR/AAR/shared library/framework, or additional third-party licence text was found in the inventory. This absence does not eliminate notices belonging to separately resolved dependencies.

The AND expression describes cumulative licence coverage across shipped contributions. It does not mean each independently BSD-authored file was relicensed under Apache or that either licence can be selected alone.

## image_picker 1.1.2

**Technical class for the package-level composite scope: Needs Verification. Recommended package-level concluded value: retain `NOASSERTION` until the carry-over scope is accepted or clarified. Scoped runtime-source candidate: `BSD-3-Clause`.**

The archive has one runtime Dart implementation, `image_picker/source/lib/image_picker.dart`; lines 1-3 explicitly identify the Flutter copyright and BSD-style licence. Lines 5-19 import/export the platform interface, while `pubspec.yaml:12-26` selects external platform packages and lines 28-37 declare those Pub dependencies, including image_picker_android. Its own source archive does not contain the Android runtime FileUtils implementation. The archive contains 112 example files, two test files, and package metadata in addition to that one lib file. The Android Java files present are example/instrumentation activities, all with BSD headers, rather than aFileChooser source.

A full-tree attribution search, including hidden files, found no `aFileChooser`, `Paul Burke`, `OpenIntents`, Apache grant, alternate explicit grant, or adaptation notice outside LICENSE. All source-code files in the surveyed extensions have the Flutter BSD header except `example/windows/runner/resource.h` (Microsoft Visual C++ generated resource declarations) and `test/image_picker_test.mocks.dart` (explicitly Mockito-generated from this package's test). No separate licence is declared for either exception.

The evidence supports interpreting the Apache block as broader umbrella / historical attribution, consistent with the separately shipped Android implementation. It does **not** provide an explicit release-authored statement that the block is inapplicable to the entire wrapper archive. Accordingly, BSD-only is defensible for the expressly headed runtime Dart file, but collapsing the existing package-level uncertainty to BSD-only without documenting and accepting this scope inference would overstate what is directly proven. A package-wide AND expression also overstates verified direct Apache-code presence; a transitive dependency should remain its own record. No OR expression is supported.

Close this specific uncertainty with a release-specific upstream statement or an explicitly accepted scope analysis that distinguishes the archive's source from its platform dependencies; retain the full composite text in either case. This is a bounded provenance question, not evidence of restrictive or incompatible terms.

## image_picker_ios 0.8.8+4

**Technical class for the package-level composite scope: Needs Verification. Recommended package-level concluded value: retain `NOASSERTION` until the carry-over scope is accepted or clarified. Scoped compiled-source candidate: `BSD-3-Clause`.**

`image_picker_ios/source/ios/image_picker_ios.podspec:13` expressly declares BSD and points to `../LICENSE`; lines 17-19 select `Classes/**/*.{h,m}`, public headers and the module map. This metadata strengthens the BSD-only reading for the compiled plugin source but refers to the same composite licence and cannot silently erase its second grant.

Both Dart runtime files (`lib/image_picker_ios.dart:1-3`, `lib/src/messages.g.dart:1-3`) and all 14 Objective-C implementation/header files in `ios/Classes` carry the Flutter BSD-style header at lines 1-3. This includes `FLTImagePickerPlugin.m`, `FLTImagePickerImageUtil.m`, `FLTImagePickerMetaDataUtil.m`, `FLTImagePickerPhotoAssetUtil.m`, `FLTPHPickerSaveImageToPathOperation.m`, and generated `messages.g.h/.m`. The module map contains module configuration rather than aFileChooser source. Every source file surveyed across runtime, tests and examples has the BSD-style header.

The 87-file inventory contains no Java, FileUtils, vendored framework/static archive/shared library, or alternate licence/NOTICE file. Full-tree text search found no aFileChooser, Paul Burke, OpenIntents, Apache grant or source adaptation notice outside the composite LICENSE. The `copied from` comments at `ios/Classes/FLTImagePickerPhotoAssetUtil.h:22,30` describe copying user image metadata, not copying third-party software.

Thus the exact archive supports BSD for its explicitly headed runtime implementation and supports treating aFileChooser text as broader umbrella metadata. Its applicability to the entire archive is not expressly disclaimed by upstream. The same bounded carry-over question remains as for the wrapper. Do not infer Android's Apache component is physically distributed by this iOS source archive, and do not infer an OR grant. A narrower compiled-source record can use BSD-3-Clause with its scope and full licence retention stated; the package-wide record should retain NOASSERTION under the conservative evidence threshold used here.

## External native and other dependencies

`image_picker_android/source/android/build.gradle:40-52` declares Maven dependencies: androidx core 1.10.1, annotation 1.7.0, exifinterface 1.3.6, activity 1.7.2, Kotlin BOM 1.8.22 and test libraries. The Gradle plugin appears at line 11. These are declared external components, not bundled source demonstrated by this review. Neither their licences nor resolved production presence are concluded here.

`image_picker_ios/source/ios/image_picker_ios.podspec:20` declares Flutter; it does not declare aFileChooser or another embedded CocoaPod. Its `s.version = '0.0.1'` at line 6 is podspec metadata and must not replace the Pub release identity 0.8.8+4. The podspec itself states that this plugin is downloaded by Pub at line 10. Apple SDK usage and separately resolved Flutter/CocoaPods components remain separate records.

Similarly, the wrapper's Pub platform dependencies and both implementations' platform-interface/Flutter dependencies are distinct components. No Maven or CocoaPods remediation is proposed by this review.

## Decision boundary

The exact-source review resolves Android's actual composite code to a supported AND expression. It preserves the full carried terms and distinguishes verified BSD file-level coverage from unresolved package-wide scope in the wrapper/iOS records. It does not promote any row to legal clearance. No counsel-only ambiguity was identified in the grant texts; the remaining issue is evidence scope, so **Needs Verification**, rather than **Counsel Review Required**, is the appropriate current technical classification for the two conservative NOASSERTION rows.
