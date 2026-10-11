# Exact font provenance review, 2026-10-11

Evidence-only technical review. **Do Not Ship remains.** No binary, font selection, glyph, application manifest or UI was changed. No legal clearance or native release verification is asserted. Historical `7f3209eebb270aaef11d875c0d214467619a0627` remains **NOT RECOVERED**.

## Inventory and scope

The tracked repository contains 13 font binaries, all explicitly declared by `budget/pubspec.yaml`; the whole `assets/fonts/` directory is also bundled. They map to seven existing font components. The observed Flutter test asset manifest additionally contains MaterialIcons from the pinned SDK and three MaterialSymbols variable fonts from locked `material_symbols_icons` 4.2768.0. The package archive also contains three source-only `rawFontsUnfixed` inputs. These seven dependency binaries are inventoried separately under their existing SDK/Pub components; they are not seven new unresolved declarations. Test assets are evidence of input selection, not release binaries. No Figma source/acquisition record established additional rights.

`manifest.json` records complete SFNT name metadata (including copyright and embedded licence strings), binary hashes, weights, filenames, source classifications and retained licence locations. Embedded strings are not grants. Avenir Black declares weight 750 internally but the app selects it at 700; this pre-existing mismatch is recorded, not changed.

| Component | Binary/style count | Classification | Exact source result |
|---|---:|---|---|
| font:Avenir | 2 | Counsel Review Required | No acquisition record or embedding/redistribution EULA. Embedded copyright and commercial vendor URL are not a grant. |
| font:Inter | 2 | Needs Verification / Do Not Ship | Official v3.19 archive checked in full; no exact SHA-256 match. Version label alone does not establish byte provenance. |
| font:DMSans | 2 | Verified with conditions | Both bundled files match exact official Git blobs and independently downloaded bytes. All supplied copyright/licence texts retained. Runtime licence/notice delivery still requires release verification. |
| font:Metropolis | 2 | Needs Verification / Do Not Ship | Former author repository returns HTTP 404. No authenticated exact-source licence payload found. |
| font:RobotoCondensed | 2 | Needs Verification / Do Not Ship | Official Roboto v3.008 archive checked in full across static variants; no exact byte match. |
| font:Inconsolata | 2 | Needs Verification / Do Not Ship | Official upstream and Google Fonts v3.001 static files and current CDN checked; no exact byte match. |
| font:Icons | 1 | Needs Verification / Do Not Ship | MoreIcons 1.0 generator metadata does not identify glyph sources, licences or reproducible build; historical replacement NOT RECOVERED. |

## Authenticated DM Sans mapping

Both version 1.200 / ttfautohint 1.8.3 fonts match the official `googlefonts/dm-fonts` repository at commit `4412393b7d2de9fe7a92064c2dce9b5af5d7fd26`, paths `Sans/Exports/DMSans-Regular.ttf` and `Sans/Exports/DMSans-Bold.ttf`. SHA-256 and Git blob identities match independently fetched source bytes. `DMSans/commit.json`, `tree.json`, both binary payloads, `LICENSE.txt`, `OFL.txt`, `AUTHORS.txt` and README preserve the source record.

[Pinned official source](https://github.com/googlefonts/dm-fonts/tree/4412393b7d2de9fe7a92064c2dce9b5af5d7fd26/Sans/Exports). `Sans/LICENSE.txt` contains the historical Indian Type Foundry/Google notices applicable to this retained distribution; the newer `Sans/OFL.txt` and root authors are also retained rather than substituted for them. Embedded historical Poppins reserved-name text is preserved unchanged. No font modification or rename is authorized by this task.

Declared licence becomes OFL-1.1, with conditions to preserve supplied notices and OFL terms, handle reserved names if modifying, and verify actual release notice delivery. SBOM licence conclusions stay NOASSERTION. Repository retention is not proof that notices ship in every target. Final release-notice compilation remains a separate open gap.

## Negative comparisons and unresolved evidence

`comparisons.json` records SHA-256 of official Inter 3.19 and Roboto 3.008 release archives and every font member. Neither contains an exact bundled match. Inconsolata 3.001 upstream static and Google Fonts historical static files also differed. Current Google Fonts CDN output for these three families differed. These bounded negative searches do not prove no matching upstream distribution exists; no equivalence was inferred from names, glyph appearance or version metadata.

The former author URL `https://github.com/chrismsimpson/Metropolis` returned 404 during this review; mirror licences do not authenticate these bytes. Avenir has no verified acquisition or applicable embedding/redistribution EULA. MoreIcons lacks original glyph/source/build provenance; reviewing its font container does not clear image/icon assets. All remain blocked.

## Replacement candidates — not implemented

- Inter: official Inter 3.19 `Inter Hinted for Windows/Desktop/Inter-Regular.ttf` and Bold are pinned in the archive inventory with SHA-256 and retained OFL. They differ substantially from bundled files, including outlines, layout and metrics tables. Requires owner/design approval and layout regression before substitution.
- Inconsolata: official upstream commit `fc1fc21081558b39a2db43bfd9b65bf9acb50701` static TTF pair is a reproducible candidate; exact licence must accompany any replacement. Different outlines/layout/metrics prevent a silent substitution.
- Roboto Condensed: official v3.008 static variants and historical Apache licence are retained in comparison evidence. Select the intended hinted/unhinted variant with design approval; every variant differs in bytes from the current font. Apache attribution/NOTICE handling must follow that chosen distribution.
- Avenir/Metropolis: the exactly verified DM Sans pair is an available OFL candidate, but it is a different family. Text width, line wrapping, fallback, vertical metrics and branding must be reviewed by owner/design. Alternatively supply original exact-source/EULA evidence.
- MoreIcons: no glyph replacement proposed; requires a separately scoped owner-approved icon-source/rebuild task.

No proposed replacement is claimed metric-compatible. The following measured existing metrics illustrate why family replacement needs review:

| Binary | Units/em | Ascender, descender, line gap |
|---|---:|---|
| AvenirLTStd-Black.otf | 1000 | [756, -244, 200] |
| AvenirLTStd-Roman.otf | 1000 | [756, -244, 200] |
| Inter-Bold.ttf | 2816 | [2728, -680, 0] |
| Inter-Regular.ttf | 2816 | [2728, -680, 0] |
| DMSans-Bold.ttf | 1000 | [992, -310, 0] |
| DMSans-Regular.ttf | 1000 | [992, -310, 0] |
| Metropolis-Bold.otf | 1000 | [795, -205, 0] |
| Metropolis-Regular.otf | 1000 | [795, -205, 0] |
| RobotoCondensed-Bold.ttf | 2048 | [1900, -500, 0] |
| RobotoCondensed-Regular.ttf | 2048 | [1900, -500, 0] |
| Inconsolata-Bold.ttf | 1000 | [859, -190, 0] |
| Inconsolata-Regular.ttf | 1000 | [859, -190, 0] |
| Icons.ttf | 1000 | [850, -150, 0] |

## Replay and limits

From the repository root: `python -B budget/tool/compliance/verify_font_evidence.py` checks retained hashes and binary metadata. Add `--replay` to retrieve exact DM Sans sources/notices and the pinned Pub/SDK archives; optional `--archives <directory>` uses already retained archives for the package/SDK. These source archives are not vendored a second time in Git. Network replay fails on missing/mismatched bytes. The normal Dart generator independently verifies the font proof, every application font hash, all declared styles, current font-file coverage, upstream blob identities and copyright payloads before changing any declaration.

The six remaining unresolved font components keep `font-rights` open. Other release gaps are untouched. Native Android/iOS/macOS verification: **NOT TESTED — ENVIRONMENT BLOCKER**.

## Dependency font licences and selection binding

MaterialIcons' exact SDK archive supplies **CC-BY-4.0**, distinct from the Flutter SDK's BSD-3-Clause code licence. Its font-level declaration and attribution/release-delivery conditions are explicit in the font manifest; the existing SDK component is a build-tool record, not clearance for the runtime font. Material Symbols' six exact package font files carry the retained Apache-2.0 Google/Tim Maffett notice. The three raw inputs are source-only; three declared fonts are runtime assets. These are subcomponent evidence records under existing components, not additions to the 324-package inventory or a final notice compilation.

Verification binds the current Pub lock version/archive digest, recorded toolchain version, official Flutter commit's material-font archive pin, all six package font members and selected runtime manifest coverage. Only MaterialIcons from the SDK archive is selected; the other 18 SDK font files are not declared as runtime assets by this application. Their presence in a tooling archive is not a shipping claim.
