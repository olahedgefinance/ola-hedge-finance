# Independent technical evidence review: three Pub composites

Review date: 2026-10-11. Scope: universal_html 2.2.4, url_launcher_web 2.3.1, vector_math 2.1.4. Read-only review of acquired release archives; no canonical repository or Git changes. This is licence-text/source-scope evidence, not counsel approval or distribution clearance. Assets, datasets, native dependencies, final notices and source-to-release mapping remediation were not performed.

Evidence base: `acquired/<package>/source/` relative to this report. Paths/line numbers below refer to those extracted files. Complete root LICENSE files were read, all filenames examined for additional LICENSE/LICENCE/COPYING/NOTICE files, and source/text copyright and licence markers searched with hidden/ignored files included. A supplementary source marker index is `review-other-notice-index.json`; it is an index, not a complete notice bundle. Each package contains only the root LICENSE among the named licence/notice filenames. Original full files remain the authoritative evidence.

The three archive SHA-256 values were independently recalculated and matched inventory.json. Parent acquisition supplies lockfile matching; this independent review did not itself re-read the canonical lockfile.

| Package | Archive SHA-256 | Technical recommendation |
| --- | --- | --- |
| universal_html 2.2.4 | 56536254004e24d9d8cfdb7dbbf09b74cf8df96729f38a2f5c238163e3d58971 | Needs Verification for precise included third-party source scope; explicit composite notice retained |
| url_launcher_web 2.3.1 | 8d9e750d8c9338601e709cd0885f95825086bd8b642547f26bda435aade95d8a | Needs Verification for retained platform_detect Apache scope |
| vector_math 2.1.4 | 80b3257d1492ce4d091729e3a67a60407d227c27241d6927be0130c98e741803 | Verified with conditions for the observed BSD/Zlib composite and file mapping only |

## universal_html 2.2.4

**Concluded expression:** `NOASSERTION` pending precise current third-party source scope. **Archive-declared aggregate:** `Apache-2.0 AND BSD-3-Clause AND MIT`. This is supported as the package's stated composite by LICENSE, not an OR choice and not evidence that every file bears all three licences. At the independently mapped file level, Apache-2.0 and BSD-3-Clause are clear; MIT's precise copied-code location was not established.

- `LICENSE:1-201`: complete Apache License 2.0 including generic, unfilled appendix copyright placeholder at line 189. That placeholder is not an actual rights-holder attribution.
- `LICENSE:205-209`: explicitly states this version contains source from dart-lang/csslib; `LICENSE:211-236` contains complete BSD-3-Clause terms and `Copyright 2013, the Dart project authors. All rights reserved.`
- `LICENSE:240-244`: explicitly states this version contains source from dart-lang/html; `LICENSE:246-268` contains complete MIT terms. Copyright: `Copyright (c) 2006-2012 The Authors`. Contributor list at lines 248-262: James Graham, Anne van Kesteren, Lachlan Hunt, Matt McDonald, Sam Ruby, Ian Hickson (Google), Thomas Broyer, Jacques Distler, Henri Sivonen, Adam Barth, Eric Seidel, The Mozilla Foundation (contributions from Henri Sivonen since 2008), David Flanagan (Mozilla), Google Inc. (contributed the Dart port). Preserve original complete attribution text including contact fields from LICENSE.
- `lib/controller.dart:1-13`, `lib/src/html/_html_parser.dart:1-13` and other package files contain actual `Copyright 2019 terrier989@gmail.com` and Apache headers.
- `lib/src/html/dom/node.dart:1-45` and `lib/src/html/dom/css_selectors.dart:1-45` carry both the Apache header and a separate full Dart SDK BSD grant for adopted portions; the latter names `Copyright 2012, the Dart project authors. All rights reserved.` at line 20. This is direct cumulative source evidence. `lib/src/html/dom/shared_with_dart2js/css_class_set.dart:1-32` also provides the Dart-origin notice and complete BSD text. Do not lose the 2012 attribution by retaining only the csslib 2013 root notice.
- `README.md:20-22` explicitly describes Apache licensing and separately documented adopted Dart SDK source. `CHANGELOG.md:163-165` describes an earlier switch from MIT to Apache for the sole owner's code excluding Dart SDK portions; that historical entry does not create a current MIT OR Apache option.
- Current `pubspec.yaml:13,16` lists csslib/html dependencies. `lib/src/html.dart:30-31` imports csslib and `lib/src/html/_html_parser.dart:15-16` imports html. These imports do not identify which source, if any, was copied into this archive under the root csslib/html notices. No file-level MIT grant or specific html copied-source attribution was located outside LICENSE; do not silently discard the explicit root MIT statement because of that.

**Recommendation:** Needs Verification for a fully concluded current-source aggregate/file map. Store the declared aggregate and the independently mapped Apache/BSD portions separately; retain complete Apache, BSD, MIT and Dart SDK notices. The remaining bounded fact question is the scope of the root csslib/html copied-code statements, especially MIT. No custom grant requiring counsel was observed in this package's inspected licence texts. This does not verify transitive dependency releases or final distribution inclusion.

**Condition evidence:** Apache redistribution requirements at LICENSE:89-128 (copy of licence, modified-file notices, source attributions, applicable NOTICE treatment); BSD retention/binary reproduction/non-endorsement at 216-224; MIT copyright/permission retention at 264-268. No separate NOTICE file was found.

**Repository metadata only:** `pubspec.yaml:6` points to https://github.com/dint-dev/universal_html. No exact tag or commit mapping is proven; source comments point at moving SDK branches and are not release provenance.

## url_launcher_web 2.3.1

**Concluded expression:** `NOASSERTION` pending platform_detect source scope. **Observed notice set:** BSD-3-Clause plus Apache-2.0. A candidate cumulative expression `BSD-3-Clause AND Apache-2.0` may represent retained notices, but a fully verified current source aggregate is not supported until the Apache scope is resolved. There is no OR-choice wording.

- `LICENSE:1-27`: url_launcher_web BSD-3-Clause, `Copyright 2013 The Flutter Authors. All rights reserved.` at line 3, complete retention/non-endorsement/disclaimer text.
- `LICENSE:29-231`: separately headed `platform_detect`, full Apache License 2.0, with `Copyright 2017 Workiva Inc.` at line 219 and applied Apache notice at 221-231. Preserve this full section pending resolution, rather than flatten to BSD alone.
- Current library source consists of `lib/url_launcher_web.dart` and `lib/src/link.dart`; each has Flutter BSD header at lines 1-3. No lib third_party directory or Workiva/platform_detect file-level attribution was present.
- `CHANGELOG.md:43-45` for 2.0.18 expressly says the nested third_party Safari check was removed; `CHANGELOG.md:144-154` records earlier relocation and attribution of platform_detect code. `lib/url_launcher_web.dart:32-34` contains a short current Safari user-agent check with no specific Apache/source-origin annotation. These facts do not establish whether the retained notice is stale or still covers adapted code.

**Recommendation:** Needs Verification, retaining the complete BSD and platform_detect Apache texts. The unresolved question is current code scope/history for the retained Apache section, not whether the text itself is identifiable. Do not conclude BSD-only or offer an Apache/BSD OR election. No custom grant observed.

**Condition evidence:** BSD terms at LICENSE:5-27; Apache redistribution requirements at 119-158. No separate NOTICE file found. A completed shipping notice workflow was not performed.

**Repository metadata only:** `pubspec.yaml:3` points to https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher_web; version at line 5. This moving main-branch path is not an exact release tag/commit.

## vector_math 2.1.4

**Supported observed aggregate:** `BSD-3-Clause AND Zlib`, cumulative across separately licensed code. No OR choice is offered.

- `LICENSE:1-28`: complete BSD-3-Clause, `Copyright 2015, Google Inc. All rights reserved.` at line 1.
- `LICENSE:30-46`: complete Zlib-form grant, `Copyright (C) 2013 Andrew Magill` at line 30, including no origin misrepresentation, plainly marked altered sources, and notice retention in source distributions.
- `lib/vector_math.dart:1-3` and `lib/vector_math_64.dart:1-3` carry Google 2015 BSD headers. Both include their corresponding noise source through `part` at line 31.
- `lib/src/vector_math/noise.dart:1-20` and `lib/src/vector_math_64/noise.dart:1-20` each contain the complete Andrew Magill 2013 Zlib grant. Both are part of their respective library at line 22. This supplies a concrete source boundary for the root's second licence, rather than inferring it from concatenation alone.
- Additional actual headers include `lib/hash.dart:1-3` (Google 2016) and `benchmark/matrix4_tween_bench.dart:1-3` (Google 2019). Preserve pertinent actual source-year notices, not just one root copyright. `AUTHORS:6-10` identifies Google Inc., Don Olmstead, Adam Singer and Oliver Sand; contributors are not automatically additional copyright claims.

**Recommendation:** Verified with conditions **for identification of these supplied licence texts and their BSD/Zlib source scope only**. Retain both grants and actual copyright notices; satisfy BSD source/binary notice conditions and non-endorsement, and Zlib source notice/origin/modified-source marking conditions. This label does not certify all upstream chain-of-title facts, shipping content, licence compatibility, or counsel approval.

**Explicit provenance limitations:** both noise files at lines 24-27 cite a Stefan Gustavson SimplexNoise implementation. `lib/src/vector_math_geometry/generators/attribute_generators.dart:59-60` cites a derived tangent-generation function at terathon.com. `lib/src/vector_math/matrix4.dart:1377` and its vector_math_64 counterpart cite adapted Richard Carling code. These references are not additional grants in the archive and were not followed into a source-release/provenance remediation exercise. No extra licence identifier or clearance is inferred from them. If the desired verification standard requires validating every upstream derivation grant, retain overall Needs Verification for that larger standard while keeping the BSD/Zlib notice finding verified.

**Repository metadata only:** `pubspec.yaml:4` points to https://github.com/google/vector_math.dart; version at line 2. No exact release tag/commit mapping was established.

## Review boundary

All three exact Pub archive identities are distinct from repository identity. All aggregate expressions above describe supplied package notices/source portions and not every transitive dependency, native component, bundled asset, dataset, or app distribution. No package is labelled Counsel Review Required solely because it contains multiple standard permissive grants. Unresolved source scope is expressly retained as Needs Verification where identified, and the composite notices must remain intact.
