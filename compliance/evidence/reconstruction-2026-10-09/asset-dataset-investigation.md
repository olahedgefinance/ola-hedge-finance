# Independent asset and dataset investigation — 2026-10-09

This is newly collected technical evidence for the reconstruction, not recovery of historical checkpoint `7f3209eebb270aaef11d875c0d214467619a0627` or documentation prefix `03915b45`. No application or repository files were modified by this investigator. No asset is cleared for public distribution by this note.

## Scope and method

- Canonical inspected root: `C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE`.
- `.git/HEAD` read directly: `compliance/reconstruct-verified-baseline-2026-10-09`; initial `git rev-parse HEAD`: `eb4adf8b6b8d8117bdf5f9ffa7288c6e42e3e94f`.
- Read `AGENTS.md`, `docs/project/CANONICAL_REPOSITORY.md`, `docs/transformation/06_LICENSE_REVIEW.md` before investigation. Read-only scope; canonical write gate was not needed by this agent. Ordinary Git status/log attempts failed with work-tree or filesystem permission errors in this subagent context, so no independent clean-tree assertion or complete Git-history search is made. Parent must supply repository status and authoritative start/end SHA.
- Old surviving comparison root: `C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work\Cashew-phase-2a-sbom` (governance records baseline `6a8a37668ce6b34761026e8594ae80a55ec2b851`). This directory remains evidence of the older surviving state.
- Compared SHA-256 of every current file in `budget/assets/fonts` (12), `budget/assets/icons` (3), `budget/assets/categories` (277), `budget/assets/icon` (4), `budget/assets/images` (6), `budget/assets/landing` (4), `budget/assets/static` (8), and `promotional` (55) against the same old-root path: **zero differences** in all eight groups. This is filesystem comparison, not confirmation of missing-checkpoint identity.
- Parsed each font's binary SFNT `name` table directly using big-endian offsets and Windows/Unicode decoding. Embedded metadata proves what the current bytes say; it does not independently authenticate the file's origin or license grant.
- Used `rg --files` and SHA-256 to inventory design files (extensions PNG/JPG/JPEG/GIF/WebP/SVG/TTF/OTF/ICO/FIG). No Figma `.fig` source appeared. The annex below identifies each discovered file, not an assumption that all are runtime assets.
- Primary web sources were inspected on 2026-10-09. They are live research leads, not preserved, hash-pinned historical license evidence. Two direct in-memory download/comparison attempts for language JSON and the README-pinned common-currency JSON failed DNS resolution; therefore no upstream exact-byte/data match is claimed.

## Fonts: present bytes and conditional evidence

All 12 font files are both in the broad `assets/fonts/` bundle declaration and explicit font-family declarations in `budget/pubspec.yaml` (lines 148 and 181 onward). No adjacent font license text/acquisition record exists in current or inspected old font directory. The current application does not contain the replacements and five bundled font/icon license files described in the historical remediation report.

| Family | Embedded version / author evidence | Provisional terms lead | Current classification and closing evidence |
|---|---|---|---|
| Inter Regular/Bold | `Version 3.019;git-0a5106e0b`; copyright 2020 Inter Project Authors; OFL URL | [Inter upstream license](https://github.com/rsms/inter/blob/master/LICENSE.txt) is OFL-1.1 | Needs verification / Do Not Ship. Pin the actual upstream release/revision and match these bytes, or replace from authenticated release; retain corresponding copyright and full OFL. A version string alone is insufficient. |
| DM Sans Regular/Bold | `Version 1.200; ttfautohint (v1.8.3)`; copyright 2014–2017 Indian Type Foundry with reserved name Poppins, copyright 2019 Google LLC; designer Colophon Foundry/Jonny Pinhorn; explicitly OFL-1.1 | [Google Fonts DM Sans OFL](https://github.com/google/fonts/blob/main/ofl/dmsans/OFL.txt) | Stronger embedded declaration, but still Needs Verification / Do Not Ship until exact source/license tied to current bytes and notice retained. Do not import historical report's two-file clearance as fresh evidence. |
| Inconsolata Regular/Bold | `Version 3.001`; copyright 2006 Inconsolata Project Authors; Raph Levien, Cyreal, Brenton Simpson; explicitly OFL-1.1 | [Google Fonts Inconsolata OFL](https://github.com/google/fonts/blob/main/ofl/inconsolata/OFL.txt) | Needs Verification / Do Not Ship; exact source/build mapping plus full notice and reserved-name review required. |
| Roboto Condensed Regular/Bold | `Version 3.008; 2023`; copyright 2011 Google Inc.; Christian Robertson; explicitly Apache-2.0 | [Historical Roboto project Apache license](https://github.com/googlefonts/roboto-2/blob/main/LICENSE) | Needs Verification / Do Not Ship. Do not substitute current-family licensing for this specific historical binary. Obtain exact source/build and applicable notices; retain Apache text and any NOTICE obligations. |
| Metropolis Regular/Bold | `Version 1.000;PS 001.000;hotconv 1.0.88;makeotf.lib2.5.64775`; copyright 2016 Chris Simpson; Victory One Media Pty Ltd; no name-table license text/URL | Upstream `chrismsimpson/Metropolis` request unsuccessful in this run | NOASSERTION / Do Not Ship. No exact origin or terms recovered; do not infer rights from similarly named redistributed copies. Obtain primary source/terms or approved replacement. |
| Avenir LT Std Roman/Black | `OTF 1.029;PS 001.001;Core 1.0.33;makeotf.lib1.4.1585`; Adobe/Heidelberger copyright 1989/1995/2002; Adrian Frutiger; Adobe legal URL only | Embedded proprietary-rights metadata, not acquisition evidence | Counsel/license administrator / Do Not Ship. Need purchaser/licensee, acquisition, exact EULA/version and app/web/source redistribution or embedding scope. No purchase or transferable license grant found. |
| Custom `Icons.ttf` | Family `MoreIcons`, `Version 1.0`, copyright 2023 original authors at fluttericon.com/fontello.com; generator URL only | About page mentions Font Awesome, but does not map glyphs | NOASSERTION / Do Not Ship. Generator attribution is not a grant for every glyph. Need original glyph sources, license and mapping or a reproducible independently licensed replacement. Historical Font Awesome 5.15.4 subset replacement was not recovered. |

For conditionally acceptable OFL paths, retain the full notice/license, preserve the font's license, review reserved font names for modified versions, and do not sell the font alone. These are prospective requirements, not a current verification result. [Inter's official license](https://github.com/rsms/inter/blob/master/LICENSE.txt). Apache obligations must be resolved for the actual selected Roboto release rather than generalized from a modern download.

## Design images and ownership

Fresh enumeration finds **437 design files**: 370 runtime/platform candidates and 67 source-only historical/demo files. The breakdown independently reproduces the broad historical size, but none of the report's nine clearances is inherited. Conservative current register: 435 Needs Verification / Do Not Ship, two Avenir files Counsel / Do Not Ship. These are evidence status labels, not legal conclusions about infringement.

| Group | Fresh count and locations | Evidence / action |
|---|---|---|
| Category images | 277 `budget/assets/categories/*.png` | About page `freepik-credit` links Flaticon/Freepik (`aboutPage.dart:206–209`). This is a group attribution clue, not a per-file asset ID, author or download-license certificate. Get source asset IDs, acquisition date/account/license, modification and redistribution terms. Do Not Ship. |
| Onboarding illustrations | 4 `budget/assets/landing/{BankOrPig,DepressedMan,Graph,PigBank}.png` | About page also credits PCH Vector (`aboutPage.dart:214–216`). No exact mapping between illustration and original Freepik asset recovered. Do Not Ship until mapping and license evidence. |
| Empty/search art | 6 `budget/assets/images/{empty,empty-filter,empty-old,empty-old-filter,no-search,no-search-filter}.png` | No exact source/creator/terms found; filtered derivatives require original-to-derived mapping. Do Not Ship. |
| Seasonal art | 2 `budget/assets/icons/fun/{party-hat,santa-hat}.png` | No per-asset author/license records. Do Not Ship. |
| Application/platform visual derivatives | 68 = 4 `budget/assets/icon`, 32 Android, 27 iOS, 5 web (includes `favicon.ico`) | Inherited Cashew artwork. Need original rights plus transformation map and branding/trademark review. Existing provenance of code does not prove graphic rights. Do Not Ship. |
| Text/icon fonts | 13 | See font table above. |
| Promotional | 55 `promotional/**` | Not declared as Flutter runtime assets; store badges, screenshot composites, banners and thumbnails can still be redistributed in source or marketing. Historical/source-only; no marketing export or release until cleared. Retention questions may need counsel. |
| Vendored package demo images | 12: 2 under implicitly_animated_reorderable_list, 10 under sliding_sheet | Source-only example/demo assets. Adjacent package MIT license does not authenticate independently sourced graphics. Require graphic-specific evidence; do not count as verified merely because package code is MIT. |

[Flaticon current legal terms](https://www.flaticon.com/legal) are a research starting point only. The historical download terms and user's actual acquisition entitlement must be associated with each affected asset. A credit link alone is not a download certificate or proof of source redistribution rights.

Figma/AI: local scanned files and surviving reports did not establish editable Figma creator history, contributor assignments or the Road to Wealth AI asset's exact file, model/version, prompt, references and historical terms. The AI Road to Wealth and Figma gaps are report-only leads in `REMEDIATION_REPORT.md:27` and `SIX_GAP_CONTINUATION_2026-10-04.md:51`. Do not assert a founder-original or AI-cleared asset. No Figma/AI artifact was generated or altered. Collect creator/editable version history and source reference rights, then qualified ownership review where needed.

## Currency and language datasets

The current `budget/assets/static/README.md` names six upstream URLs but contains no complete license/version manifest. All eight static files match the older surviving baseline. Because `pubspec.yaml` declares both `assets/static/` and `assets/static/generated/`, the broad bundle includes source inputs and README/conversion script as well as the specifically named generated JSON and language names; inspect the final asset manifest before reducing distribution scope.

Runtime: `budget/lib/struct/currencyFunctions.dart:10–11` reads generated currencies; line 22 uses unpinned `@fawazahmed0/currency-api@latest` USD rates. `budget/lib/struct/languageMap.dart:14` reads language names. Dataset names are not licenses.

| README source | Current direct finding | Required closing evidence |
|---|---|---|
| [manishtiwari25 gist](https://gist.github.com/manishtiwari25/d3984385b1cb200b98bcde6902671599) | Live gist is a mutable countries/states/data compilation; exact historical snapshot not identified | Pin revision and source provenance; identify author/database rights and applicable terms; map to `currenciesInfo.json` only after comparison. |
| [yonilevy crypto-currency-symbols](https://github.com/yonilevy/crypto-currency-symbols) | Current repository displays an Unlicense license; no current local input file is explicitly named symbols.json | Pin source revision and license, identify which records were used and transformations. Do not treat repository-level current Unlicense as proof of entire composite dataset. |
| [fawazahmed0 exchange-api LICENSE](https://github.com/fawazahmed0/exchange-api/blob/main/LICENSE) / README's npm latest currencies URL | Current project LICENSE is CC0-1.0; bundled snapshot and historical version not pinned | Capture exact source snapshot and license, investigate underlying data sources as appropriate, document snapshot-to-local transformation. Live rate service also needs its own operational review. |
| [ksafranski Common Currency](https://gist.github.com/ksafranski/2973986) | README does pin raw revision `5fda5e87189b066e11c1bf80bbfbecb556cf2cc1`; no license found in inspected gist text; attempted direct compare blocked by DNS | Retrieve exact raw revision, compare to `currenciesInfo2.json`, locate applicable original-source terms or replace. A pinned URL helps identity but does not confer rights. |
| [keeguon countries](https://gist.github.com/keeguon/2310008) | Mutable gist; no license found in inspected page text | Pin exact revision, compare to `countries.json`, obtain applicable permission/content rights. |
| [L-P native-language-list](https://github.com/L-P/native-language-list) | README says based on umpirsky/language-list; no LICENSE link found in inspected repository page; direct upstream JSON compare failed DNS | Trace full source chain and historical revision/license (including upstream locale data), compare to local `language-names.json`, document alterations. Public GitHub availability is not permission. |

`Convert.py` is surviving transformation evidence: joins base currency dictionary with the currency-info list by lowercased code (the loop has no break, so the last matching record wins); copies Currency/Code/Symbol; joins CountryName to countries by lowercased name; otherwise takes name/code/symbol_native from the second dictionary; otherwise creates a NotKnown record; removes Symbol if equal to Code; dumps Unicode JSON indented two spaces. It does not consume a separate crypto-symbol file and does not document how the four inputs were acquired. No exact regeneration was performed because the delegated scope prohibits application edits. The mapping is incomplete until input snapshots/terms and any later hand edits are proven.

Current composite currency/language classification remains **NOASSERTION / Needs Verification / Do Not Ship**. Even potentially permissive sources cannot clear the unknown parts of the composite. Engineering can establish source/version/transform provenance; counsel decides unresolved database/content-rights interpretation if evidence leaves ambiguity.

## Surviving evidence and candidate port paths

These are candidates to port as newly reviewed evidence only; no port was performed:

1. Old-root `compliance/components/non_pub_components.json` (SHA-256 `f63d4579b7711cf3245899fb7a6e957745ef3eeaa66526f15b1b13e940af9b4f`): explicit unresolved font/image/dataset records. Reuse schema/data conservatively, refreshing all file hashes and current paths. Candidate destination `compliance/components/non_pub_components.json`.
2. Current `budget/assets/static/README.md` and `Convert.py`: exact surviving URL/transform evidence. Preserve provenance copies under a new dated evidence directory; do not fabricate acquisition dates or upstream hashes.
3. Current `budget/lib/pages/aboutPage.dart`, `budget/assets/translations/generated/en.json`, `budget/pubspec.yaml`: surviving credit/bundling evidence; quote/hash into new evidence record with current source identity. No need to change application code for this investigation.
4. Recovery-root `reports/REMEDIATION_REPORT.md` (SHA-256 `e212376699a7ca035c71b247e9bf64a97873552846659ece941a2a37b04d5ad4`) and `reports/SIX_GAP_CONTINUATION_2026-10-04.md` (`bf9c5a82fb5ca54687706b9ce9a9b85b66f685b50005bcffe9fefb593b6cfeb5`): historical claims only. If ported, label report-only under `compliance/evidence/historical-reports/`; do not use as exact font replacements, licenses, tests or owner-approval evidence.
5. This fresh note/annex could feed a new `design-assets/inventory-2026-10-09.json` and evidence register after parent review. Do not reuse the historical `inventory-2026-10-02.json` name as if that payload were recovered.

Missing evidence not found in inspected roots: exact authenticated upstream binary/hash package for these fonts; the report-described font replacement payloads/license bundle/icon rebuild source; per-image download certificates; Figma editable ownership record; AI generation record; complete dataset license/source/transformation map. Searches were bounded and do not prove that no copy exists elsewhere.

No Flutter tests, release builds, visual regressions, or legal sign-off were performed. Checks here were file enumeration, SHA-256 equality, binary metadata parsing, current source/manifest inspection and primary-source web research.

## Fresh exact-byte inventory annex

The following rows are current local byte hashes, not upstream source hashes. Every design row defaults to Needs Verification / Do Not Ship except Avenir (Counsel / Do Not Ship); source-only rows are separately identified by their path/group above. Dataset rows are NOASSERTION / Do Not Ship pending provenance. Recompute before porting if the parent changes assets.

| Path | SHA-256 |
|---|---|
| budget/android/app/src/main/res/drawable/addtransaction.png | 73d79b3bcd24ed2fea6ce2ba634b8ea21616ab6ea144b2681ea8cee917f43f07 |
| budget/android/app/src/main/res/drawable/net_worth_plus_widget.png | d304db057ae1ff082da25abd2d45a794f55fea08e184cefe153db78d3ee66321 |
| budget/android/app/src/main/res/drawable/net_worth_widget.png | 87a63c107f4c7b2a3983f2c8cb3485fef4677120b4b96e519a76cd27d2295d95 |
| budget/android/app/src/main/res/drawable/notification_icon_android2.png | 33c62b2a4b0563a84436ea720a8afd326f2eb7b5330281c8548dcd72e4277323 |
| budget/android/app/src/main/res/drawable/piechart.png | fadd97214c00de0d27b521bfd9b1e222c44797bac5a82010ecc4fcf731ce3e12 |
| budget/android/app/src/main/res/drawable/piggybank.png | 4f197f26b18d2e10b47de3a81a65a0bb85b103ce7335150ddea5db8834c9ec5d |
| budget/android/app/src/main/res/drawable/plus_button.png | 5daaf4e1990b408eb8e8bb9c255059982e2f1a8812b270d187fae18077aa1c27 |
| budget/android/app/src/main/res/drawable/plus_widget.png | 032fe0662c9c248b8ce24e3da9e99886ecabe0c8c2c98a91c261b441b766c396 |
| budget/android/app/src/main/res/drawable/plus.png | e19867a3c8618bd1fc25440b1840a9d15d3fb56ae4c25c77804575040c556bbc |
| budget/android/app/src/main/res/drawable/transfer_widget.png | 6377d3ffbae725de8e8187bbeaa281a097257b5a46f703b1e5e0db1c2ea21966 |
| budget/android/app/src/main/res/drawable/transfer.png | 1f6ef9c52cd3bb8b6b8d4f408222da8cd70af32c49075a22b1aac20dd83da539 |
| budget/android/app/src/main/res/drawable/transfertransaction.png | dde66042ec0c132e760c688a2454060b4142bdf1416cc958a18afaa3a569fb05 |
| budget/android/app/src/main/res/mipmap-hdpi/ic_launcher_background.png | 7cad0a0aa808d180eff514111208dc4bfe1543529bbb3de2c867a960498f33c2 |
| budget/android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png | 3e3fd099fc5ed07de5e2da7ad2475dbbf0b264908d4c76fe22eb99afa4e811ee |
| budget/android/app/src/main/res/mipmap-hdpi/ic_launcher_monochrome.png | 1b03ec4dd1755bee30159a4cd6fec3409bac8cf3da85351ec58b84b72612b079 |
| budget/android/app/src/main/res/mipmap-hdpi/ic_launcher.png | 74e5dc73d0a41d519e6cf347012991a29f6289989460ad5cacefe6d3e8f6450a |
| budget/android/app/src/main/res/mipmap-mdpi/ic_launcher_background.png | f5e3c7cc161bb1397a31b3f96ac43341e9bdf53a3f4355fb970f6ee56212a3fd |
| budget/android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png | 4b84692399423891e384376ebb9cb49573fb42149cf7a438fb1faaa2ded01e74 |
| budget/android/app/src/main/res/mipmap-mdpi/ic_launcher_monochrome.png | bdd054a1b10b7a64060e8856a16c528db8c0c62ee382f54c02c0797ae9afb341 |
| budget/android/app/src/main/res/mipmap-mdpi/ic_launcher.png | 5e1f26b8cef95323f45938b48a939f30fe34d99d27f025b95dc4476503dd521d |
| budget/android/app/src/main/res/mipmap-xhdpi/ic_launcher_background.png | 84fc7230d911e91428ebc1b246506db30c6f3dea603aa1c641acf3cc2cebe279 |
| budget/android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png | ed9e801cd7f24595c19057adefdd5bae2b6081ba7786d5744f79a023b72d81a1 |
| budget/android/app/src/main/res/mipmap-xhdpi/ic_launcher_monochrome.png | c5ddd353eac81f12f4f2a14115781e9f603b34b207c00a474020c9287d830fb3 |
| budget/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png | 85545dd792201351e654cc9980c37f76d809d5300be49d4422c8573750b3dd98 |
| budget/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_background.png | d7e404365ec21c486c4b8bbf490d8f1eba9ed39bf0aac4a09830e14d9ecc575e |
| budget/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png | 2919dda02f6eff7b34721655fc7160747a1f6198eddecd719f8771226ab44a9f |
| budget/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_monochrome.png | 865d38d8430e05d42c80b95dcde1ed94258eeffabca195b0e06108815b15210c |
| budget/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png | b7cd050332cde1ac81a772fe2096ac735f784aa261026a0ac1369da20608a918 |
| budget/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.png | 6fb9af44f7460885a00bd50402bc45579e90ec55064cc20d665f83a3df709d59 |
| budget/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png | fa765b778ff9b90731768db2c39f6c1ec3a133152671530b2d8166d929b32648 |
| budget/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png | 50046074cfccd1568765cbd90018fa5d15b51de8435ac542fc760ea58634a62e |
| budget/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png | ca6f9ace25b14a53224e19bf2f6319b7d75eb434ce5a0bf45e312dbcaa32392c |
| budget/assets/categories/3d-printer.png | 6cf22cbc5a943d14704ba383a1e67c74a56ebf77725d44fda38ac089eda5e7b2 |
| budget/assets/categories/air-hockey.png | b2ebf30fbb8444b8232773b85de1850a6da0b7181d1c7c65ff755c35e54d3066 |
| budget/assets/categories/anchor.png | 6527c660d3e8f3f9ec1ce23ca7f921a5939c89c5603d1df6360f6979a0fc7a92 |
| budget/assets/categories/antivirus.png | b2d24250d256588097988157358dd9c7e556dd1d07741a3b9ffec29696a40af6 |
| budget/assets/categories/apple.png | d72563a87dff2480aa5fe4b9541c7bdd808499b8dca1cfce549d414e07ef804c |
| budget/assets/categories/atm-machine(1).png | a0e3e89177222fae9ad77b5b1b61fae2ef74e290ffd91424b9452ee06bb27534 |
| budget/assets/categories/atm-machine(2).png | d9e254dc4480761962a79bf2fa91aef58d51300e7a4f2427f324da42ae99767d |
| budget/assets/categories/back-undo-arrow.png | 18aae041bc1fef02007b55132d4359ac5a494d36fbff4ffdb79b0bc3b89311db |
| budget/assets/categories/ball.png | f67317300bef26a2df0c98590d3896b5f61dada76f61c1ea2ea70be47b05d9a5 |
| budget/assets/categories/balloons.png | 6f5eec4d0735112fbae25077bdd21f5c090c1a3e01a7b851136e19dc0bd3902d |
| budget/assets/categories/bank.png | 26632dbe6a530f8967c5d66305bb783aa8e375decdda641f894ffe0e47ae1d6b |
| budget/assets/categories/barber.png | 7106921392fc3dc69a04763a40add6da51ac51968727c92d5c9392b6243ead4a |
| budget/assets/categories/baseball-player.png | 4afa9a3d33775cb75efab175089cfd02497a4dc90b180e3f0359e3434b02978a |
| budget/assets/categories/battery-charge.png | 1f03763faf23f80519af18f0046933c35bf3002a626d4755796d2b1b4dd53c64 |
| budget/assets/categories/beach-umbrella.png | d7687f3676315b13495358d4f48df76aff999377bcbfb19d9a920799f5e4cc3d |
| budget/assets/categories/bicycle.png | 37fb243072c2253ad5fda6269cdceb6417a9b757aed312007605bed00955ab4b |
| budget/assets/categories/bill.png | c61b8be4f101efd63ff423bff9553ebb70d059c849e2373fcddb24a7c372ffb6 |
| budget/assets/categories/bills.png | 279177aed7689d4b1401ecf5bfac632b9dc10d0dfef1b9103d8cc0118de049f2 |
| budget/assets/categories/binoculars.png | af6a065a2c4a1bf27f3735627d29c428743df1e6430a0a8e579c8c088acfc2bd |
| budget/assets/categories/birdhouse.png | 6858783518cfc51fc7f8b9b6b09cba75455797afc8f71819817ff41bc3d326d8 |
| budget/assets/categories/bookshelf.png | 2d5f63c67a987f83ac890866949aaeb41580bd56150b6cf3a76756bd4b29323b |
| budget/assets/categories/bottles.png | 3c460640312a2b5d7efd7af4f3426880552f0b4f9501cd12b307210d5a4b388c |
| budget/assets/categories/bouquet.png | b676518b296e3fa1c89eaaac5f7ec1806317f8ec3205ad1d68963dbb17dd5023 |
| budget/assets/categories/bowling.png | 24ce34a5102adb7e97c06c9da1d6ab41c0667c1ec08f78ccfd126e4130241053 |
| budget/assets/categories/box.png | f17b1192866fdaa3ed76e36ab8c3d6d17c3ffd51dedb139136a604993c2abb5f |
| budget/assets/categories/bread.png | 2a978d25cabca889999c5d489fbbfab1960b2be13d6e5c61db1860fc2979131b |
| budget/assets/categories/briefcase.png | e43d89c3cd38a5e01efc2f7da64bf20979f2665dd8375a71d33e5ec4b638b85f |
| budget/assets/categories/bubble-tea.png | 65e0581bc2ff31605be889c3ac6bd6cdf573c5980f0490e5170189c21979b8a6 |
| budget/assets/categories/butterfly.png | 477218c68fd0f67233283efb50cb004ade053bd2859315a12f315b909a3210bc |
| budget/assets/categories/cabin.png | 879b64408d461c2b927d1b8c7db204f6176c04a2dfa85622559af37ce4961418 |
| budget/assets/categories/cactus.png | 6e41f31cd824f81eae04a76772c1e893bc6efe1a93892f3b8073319d8afaa44e |
| budget/assets/categories/cake.png | 5f96c4f35db34ebd468c15f9742377b83f3952eca35df9ae1a1d9630d76589df |
| budget/assets/categories/calculator.png | 7b191121cf370d6ea3f7311d9ca73ef6b11b45a0ed007afd6ead73c5e317dffc |
| budget/assets/categories/calendar.png | 07905b3c0ec9c96bee99f591597ae7429f9797cac33763f49a62918d5e9de363 |
| budget/assets/categories/camera.png | 8b0f4b247197b5926f756b0d9dd61a55ec3b94a7daa9cb3c5e2e7423946a8586 |
| budget/assets/categories/campfire.png | a596f24f9fc0163ec6f4667d6ea86f812663849f1b4b1cc4580b187be5d0744d |
| budget/assets/categories/candy.png | 3243bdb5cb368b13780a25ac5b781f6101c609332baab4e3170b0268ed3cf1a7 |
| budget/assets/categories/cap.png | ae39c811ff3470fc428c57c9a4709164fb732439fd542bd53047611f30de2cb3 |
| budget/assets/categories/car-charging-station.png | afb3f627b34dd4013ecf917bcdf6203aa6a74ea0c61663005bb199632baf27da |
| budget/assets/categories/car-key.png | bc9b85640ca5e61b4b08a411093310431d2a777a77222724d0470567c0ddf2b8 |
| budget/assets/categories/car.png | 5c8faaa91a478065315c78ded83eb0babf8d697876b868df66874041a53ca1a8 |
| budget/assets/categories/car(1).png | de16915a3e30aa1a0a22a3e05161f0de1a2134c980711fc508f881f11de8e445 |
| budget/assets/categories/car(2).png | be3634c0f62ce68b25a75872e791cbf22c088d2768fc8e5a8b4397e616f32be1 |
| budget/assets/categories/cards.png | 2bc5a5dbcfbbea3b8b1d960357a99d81ed8be08cb67b00efaa539385339a39b1 |
| budget/assets/categories/cash-bill-dollar.png | af248fafcbeff21405753d3c0055df533c669057b71aeb816467d1b83ac1ac7d |
| budget/assets/categories/cat.png | 5f25142f81619bbe495ca84a8367b97bc4582969ae103f4908eab5636bca64f4 |
| budget/assets/categories/celebration.png | 7404614c14c3c474cbf07bc4eb4432208a8c93f6024174b5e3222c693ffcf6cd |
| budget/assets/categories/charts.png | a71fa5b12520ad71b082ac8f12ff23bc2982fe4668ede8d9ca6cb48b0f8f4e67 |
| budget/assets/categories/checker-chess-board.png | 2acebae2bf07e42ebe9e530b8a9f6ac5f8e14f1dfd44d3d2d1eefbf31023b6a8 |
| budget/assets/categories/chef-hat.png | 4efde422b233538091b13f1d148bc80196e5f7283473f5866671802f88f20f15 |
| budget/assets/categories/chess.png | 859e89f3decf6cd3be6141263243152768e7252fd895d20ca14fc72994ec3a55 |
| budget/assets/categories/christmas-tree.png | 3c4b20d49e980dae858bc005397b3acf21e3ba61df606cb6965a4818f1156086 |
| budget/assets/categories/church.png | 163b82800ab6b012035c58b0fc204b56d4b181405437f2e3f12924068a8e4d46 |
| budget/assets/categories/cleaning.png | 92ef62d7ad51b43e0eac1df814680211a32aad4ccf8f1aea628e836cab13007f |
| budget/assets/categories/clipboard.png | 0eea58dce11c05d53912f20967c95a0d0f3adc0032883566d161f9a3e3854bf4 |
| budget/assets/categories/clock.png | 7b1d5fcec71fdd2531b4d06288a744883f23cb28e976c24de025097984db58b3 |
| budget/assets/categories/clothes-hanger.png | a8448ef3fcd9cf0e6e7e42f65d153685562d4fe0d594edcb4f47e0f58820d9f7 |
| budget/assets/categories/cloudy.png | 0fab46ca0d051bd65793afa56a6f0a4ff31f82a08ffbbdaf8df5533826177fad |
| budget/assets/categories/coconut-tree.png | a61256e11c1424a6f3676d1ddb7cc4555cc3f3ed98e2e9d4eccb1996d95fc2a4 |
| budget/assets/categories/code.png | 0379bbe42d6daf191310991b247fb27631f96303c850b7f1ce4bd8b04c0b0baa |
| budget/assets/categories/coffee-cup.png | d9a65a11dce95c93624b00f0fc9babbe9c3c23dbec96c27c0d0cbfe0d1b996e9 |
| budget/assets/categories/coffee.png | bbd735ebb1013798508bd10588f556e84500dc05030f0423760cf4596bf1cb9b |
| budget/assets/categories/coin.png | ac7bee3e0c85273d1fd39e0518655b197d2831f827b5b603a0ce3ebd1ddaffd4 |
| budget/assets/categories/color-palette.png | 3c2f7903359635dc77cb2703bad180b94869df7dfb2d0f3e7bb252a9c468fa57 |
| budget/assets/categories/compass.png | 85f24e2996ca50239c9826a2a8fdc11d0d10423cfa8f41a37973ca2f9669966b |
| budget/assets/categories/confetti.png | 187bf4119253073bb83d0c60aa3799592830107d50a00d4d9b4fb9c88221eddc |
| budget/assets/categories/confetti(2).png | eef7654b0948c50f227a9689b807d5e62d3e078178d0dfba0337f98eb186d401 |
| budget/assets/categories/construction-helmet.png | 4f380a5a2d4e78d467a6c42840e39b652257c2b893c26e51868a5f281c8bb6b5 |
| budget/assets/categories/cookies.png | 03f4e47ddeb3dc17cef1e2cd326c089b2b61d4db4921e3c56c8761cd9dc966b0 |
| budget/assets/categories/cottage.png | fbb7d7b041778ff26171c91dfe32a943cdeddfce14b7166ce5777617672ea8dd |
| budget/assets/categories/cowboy-hat.png | d1d1bfffb996c984155eece90d6f98c83fb22ba17531058b8983a0d3557645bf |
| budget/assets/categories/credit-card.png | 5acd44d74e3d9dddb12bacdebd9506229102700193b14cb2178d42119750056f |
| budget/assets/categories/cricket-bat.png | e3569b5ce08506b80953aaefc263492a664172eb8609f847216d733df6e98abe |
| budget/assets/categories/crypto.png | 3b2688d00948ffa1a2527d7cda9d157ff0b154416c4628788ad7ab1c2c66f2ee |
| budget/assets/categories/cupcake.png | 9e5f900b8a38030c72a7126d7858eb648bd8d2aa84f484c4a23308590a055a8f |
| budget/assets/categories/curry.png | 518bf0907328da75caecd9fb5a60e33a58b00b6cece214a752eecbd7a4f7ab55 |
| budget/assets/categories/cutlery.png | 0817f021f61cde568ebf7a17ccb2e194a79a2bd0c8b334b43dbb0de51f21785e |
| budget/assets/categories/decrease.png | 11dd37755c6721333e70e210a424d2352bb98988e5af8b38f274af92f90b751f |
| budget/assets/categories/delivery-truck.png | 26a831518ab6e7730c6b7c5b3eaf912c3c7d4c8d17d08ff25d58795dcc4274c5 |
| budget/assets/categories/dental-care.png | 09e1e3812274c4a0c3c98e7d9f2039cc9366b2d9eb2afcea464a96ba774e1600 |
| budget/assets/categories/desktop-computer.png | 44378d91d6f87c1020072bcdf7dd902b72e134d467bdb24c531dd0979aca2835 |
| budget/assets/categories/diamond.png | b30e911908d8484008263f6df9d884b31e8d6802d53412dffa1ea5c94324fa8b |
| budget/assets/categories/dice.png | 1ced4d51bb3b607aff9a82eaf3d023b71b77b4d575890d18fa6c23e5d08256bf |
| budget/assets/categories/dog.png | e6bf5d6776904169ef3b4502b46c75bec38acb35f8b486ea3835f9ea45d373db |
| budget/assets/categories/dollar-coin.png | 62df02d06b305dc237bd884ec034931c441ce70e1333a2f3fd40eaba2c81278b |
| budget/assets/categories/donut.png | 09685244bed36ab712a10403bc0179558ce364b639625decbc8437066c9f03de |
| budget/assets/categories/double-bed.png | ea6d4cda6076f1b53a2a0fdb4bd0b749c49eb7f9e789681962c05f0311477b9b |
| budget/assets/categories/dress.png | 4c21050f8d175ac5a830dd97be4de30e1f95a11923a6d6a59fd1f67c37950701 |
| budget/assets/categories/dvd.png | 0d6ece1d93f6be2d79a75715797e483418386d1e1bf8b0f0f59608aaff26b1d9 |
| budget/assets/categories/earth.png | fa9ee430ecf7d8373a76165e44d149f29c62092af68746c26dfb705c1d83d0b6 |
| budget/assets/categories/eggs.png | 648340592061974072d51df3bc28b804cd9b153185d7537f0353e6428f5f05f2 |
| budget/assets/categories/emergency-exit.png | 18edf897532c29c9f878a7d5c6124300d8779c64aa42a3edd57cd2563edaa3e2 |
| budget/assets/categories/envelope.png | f572589f5fb0c3f1e81150e87d323465c12d5d25fa242446bca12f184074c5c4 |
| budget/assets/categories/essay.png | 81131c1912b0f94b439b4572f4963d48c15a7795399f17fd1f9862f1e2c31d60 |
| budget/assets/categories/exchange-arrows-circle.png | 0cf8c32ad871461d2935255d3965feaac1dc4ab6244cf13dd0e0318ec1683b6f |
| budget/assets/categories/exchange-arrows.png | 6b5761360cab8216b890de3d6aee7e304eea6260ab757e4a053bdf7290249a07 |
| budget/assets/categories/extinguisher.png | ba4e2035bff3008d0895b63d9948c5f9d446a6c1cb909edcf9ba4c4e3bf86c7d |
| budget/assets/categories/face-mask.png | 37deba8dace438c6bba8fd1a3f4c4121e83fdab0d43b2c9e882f0e2c035abb73 |
| budget/assets/categories/fast-food.png | 690c59fb04f2fe26df002c4b72c1e6165f9b19a16d99d84a50a8ee1b90634076 |
| budget/assets/categories/favourite.png | ef3cbb152690e17a064e19ae8bb5ede965791e2b8598f7165443cdd6cddaa324 |
| budget/assets/categories/feathers.png | 1f0b38737a21443f099da1686822d91c272a0dddd051d632722f6dd1d16264db |
| budget/assets/categories/feeding-bottle.png | 72fda939ebbecc3d5e903913cea25bb18e485f2d19934a49764fd7a84abd3924 |
| budget/assets/categories/fireplace.png | 5299408cfaf5090b5326a8c0222b6db799347c979e76c20588e134ecc0110452 |
| budget/assets/categories/fish.png | 709ce05a5b887407436f3e8c818835cc62050d55ecb2f40fea7ba66390938d99 |
| budget/assets/categories/fishing-rod.png | a0ec1eddd146b2d99964853cb108a11492245d32b20fb2c766a908ba5d8f11f7 |
| budget/assets/categories/fizzy-drink.png | 400aa7df8078063c50f74b568ce836ac988067ccf6487d182bffdd191a1fe261 |
| budget/assets/categories/flashlight.png | 13ac48add35c5b8f2a3cd008e2f703c354261fbcfb48ca6305b64b1d4b5e1881 |
| budget/assets/categories/flat-tire.png | 1c4a00695b955fb5a4a71287ba1d3d649f0dff28a8adbae054c4eb92ce20bd05 |
| budget/assets/categories/flower.png | 988b21f61998c24ac8a56936a8c38b91a0e651e80719d4fc120a3b0352d8b4be |
| budget/assets/categories/folder.png | 63ef69ccd7d150e228ab4a2939990c89c0fef4d628791162ab099196006fe4e9 |
| budget/assets/categories/food-tray.png | f3ab12c3be2157c6804191533162fd9f9e9f6d79469de63156d44a8299985e3b |
| budget/assets/categories/fried-egg.png | 30b807f2170f0606821dcc4a480f53981839db0655a75be0292ac305cc0c0539 |
| budget/assets/categories/fried-potatoes.png | 8d186f7d2d06099a485e886721c809bca57bc7c3aa634ba2264f3d0184823e2f |
| budget/assets/categories/fruit.png | 549b6d13b3ff14ddd557cc6fec00f0b9d3b4c64a7f25a4419bbbfe672a7af1b0 |
| budget/assets/categories/fuel.png | 1b698e4fa8daefea5f13cb7d1b967b7357b641d27e7cf548be4348e42b629902 |
| budget/assets/categories/furniture.png | 8d57eaaf2efc99d83e5eb698f2fdd71a5e21213221cb8ba297f7ab4a881e41c6 |
| budget/assets/categories/gamepad.png | 7398150944b2e4f611b16cbbefa7f2c85cbc8b76aad271c6f234bf8169dbd8ec |
| budget/assets/categories/garden-hose.png | ab6c3c80013a081130bb90be86394b1f3823bc37a211ef3ec4ffa84c59b8b944 |
| budget/assets/categories/gas-station.png | 099ac5df6234877e10076fbb14fe21587d43bd566c7835d41d62fb5fc19d1eb4 |
| budget/assets/categories/gas-valve.png | c60584640525293d500e2bbabaf8615ceab29e5c0be88ae7c8b65b280dfbdaca |
| budget/assets/categories/gasoline.png | 07a2cc624fbca8b129f12c8e14030cd550c9491d909fe13288009cb3fe05266b |
| budget/assets/categories/gears.png | 00031ed688408d4f575d7678026e9d90bba5189f39483529b600fa45a3cbac84 |
| budget/assets/categories/gift-card.png | b66c2842717c3bd7befb95b04ba3f9bbddf71422d86610ae7098754a155ba983 |
| budget/assets/categories/gift.png | a9a7267274213b63789c67bd322225247f34187608963177f44c5c7c7e1bf5c8 |
| budget/assets/categories/glass-of-water.png | 6dd7a3930097870a6b807e3d46d56a0deb3ba1bc83ee926704ebe0d17ef4bb36 |
| budget/assets/categories/glass.png | ed38c898517e5fbbbecb2bfc5eb884f68ea38967544b68e1940e427c37849c19 |
| budget/assets/categories/golf-ball.png | ed82aac60606729b4ad30e275726de2b9a71707428d6fc53946ee5735a73cd69 |
| budget/assets/categories/golf.png | 2022502a5917127beef9311881ee5c453ee43fe4b238a2c3e8b5c82bccab7014 |
| budget/assets/categories/graduation.png | ccf9428b5fc8eb969e65d2451d810bea72e9b03f95e1b886feed1707a1f88642 |
| budget/assets/categories/grill.png | 9c7bd2152459a50a344ef22f22e28b2327b9bc7af6ab59cb196616f104589d31 |
| budget/assets/categories/groceries.png | b1a16974149d1957a13ae19d5c5b1cabe2ad25973c86be77e6633ca9d31b1d71 |
| budget/assets/categories/guitar.png | b98f3e769dd26709e4a48be8d48eb95f133078955d60cdb41e71fb83ec9b8712 |
| budget/assets/categories/haircut.png | 866247c22e43044712056463b14cd9c566a94be61ad48c25a15aee0d1f11b5b7 |
| budget/assets/categories/hamster.png | cfdb902ca8630ba9d4acea704bc4a431b177447d72879652624bafaf6f1c3a21 |
| budget/assets/categories/hand-fan.png | 16acbcfa93ea5225b2b390e53dcada81e62ab51c8c57252fae5e1900b42fb4f7 |
| budget/assets/categories/headphones.png | 53cee92fe37ba35f733d293b22c1ca30526deb79d5178dc2b2b78aacb023fbe1 |
| budget/assets/categories/healthcare-and-medical.png | 53b09173850ab8fddb8cbef0186befdd2836e452e43dbd1f045110797fe1ece8 |
| budget/assets/categories/healthy-food.png | 16343a6582ca76288323d368c6e1ac850ec221bedb8cbe69d3c31271683087e8 |
| budget/assets/categories/hearing-aid.png | 2497c14856803327debdc1ae4133090224c7b497814df2df5a9cd3d85b28095b |
| budget/assets/categories/heart.png | 70eae7bfcdff45a18ddcd035cfc68d92f8ed71eaabf7f115ff7992d14eaf6333 |
| budget/assets/categories/helicopter.png | c8a5aa3320b25eeb708c911cc572b57dfc0562f2b9609398853cf05f87fd1c3a |
| budget/assets/categories/high-heels.png | 1dccfc43b6ce79223e571c8bd7bed36781f238707cc54779cda011f14bf185a0 |
| budget/assets/categories/hiking-backpack.png | 37919f2a8e08930f6a8e7a8b684c2455bcd2c60716e82dfca520f6f3871cecee |
| budget/assets/categories/hockey-stick.png | fdd4badbc2c7c38f23ba89fbdfafd4731695293fcd225353c25af2813a16b042 |
| budget/assets/categories/home2.png | 1228338acc897e0bbb06c43a556fc612431add8e360569e4c7008502147a028c |
| budget/assets/categories/hoodie.png | 6a5ed9759846dcd133049884defe6b8075e31b0a7f4cc189925978a6a82b02e8 |
| budget/assets/categories/house.png | 2ab511a4ead3e6d54158902f37d2ec6c0aff44cb6a896d6d73360f68c51e2ec4 |
| budget/assets/categories/house(1).png | 9d66423e2feea6be0568e39501b1f91ab181789e3630c1c5fca8c0653baf61d9 |
| budget/assets/categories/ice-cream-cup.png | b4096c4b2750878f1f43f61707311e4140ef9d64cd8c44ad2403c7758a5dbb8d |
| budget/assets/categories/idea.png | 2f257d067a79231deda66352592e4d7978783b578305343d31fcea07cb2937c9 |
| budget/assets/categories/image.png | 947a88d60304b4e4a9aac8eb55dbdda5600a126ab992f64d65d2722dfa6b5de2 |
| budget/assets/categories/increase.png | 872ded0d621295275d977f5d6b91ee9b2e75ff7d7b521e9a75cf444ca4d48f92 |
| budget/assets/categories/internet-globe.png | c7027ffca6d57bd0897670d5adaa8cfd2b6109b75af20e31a004d7614c175a11 |
| budget/assets/categories/investment.png | f98dbd2b0117be2f6d93687492747a1c07e0fb6db6b763869800ade346d6ec7d |
| budget/assets/categories/key.png | 774862d5b7bac321efc1323cec9e7eb17524c060c9f78b8107598d6d9947daa1 |
| budget/assets/categories/keyboard.png | 39fbffb79b9b95358ce620c60d3328d24a7c56e0bc320ea03e6b8c82749d9831 |
| budget/assets/categories/kite.png | a003218cd29d4dca08b57bfc471ac81dda54e75ee2dcbdaca289a1fb959a6bfb |
| budget/assets/categories/laptop.png | 6b41b29cf1642234e2644ea214d05ccfdb13df3943a1b2f7aef20bb4347b9aee |
| budget/assets/categories/lighthouse.png | d7b78d2508ca44aac10ac69a04c326d84043982e9235f8bd5143e768b16db535 |
| budget/assets/categories/lightning-bolt.png | 26fab7ebc445309af8f72f1301912eec56f8db07f89882c35a25a9fdb695145e |
| budget/assets/categories/limousine.png | fd18f712587bb686d891d38254d1b1e49fcc33a4123a07e4cfcedf19a053da48 |
| budget/assets/categories/loan.png | a50599deece9f726c45c1fc3946a48771bd8a9062352d4971b429a5e6a3e5837 |
| budget/assets/categories/location-pin.png | 80ab296c4ffd5bbc1ec04d8b45206c722d460ac7172a1981bbe0df3f86592fe4 |
| budget/assets/categories/locomotive.png | 60e9a233cd3f81235c04bb8793cc3d23d852b9cb9002311e49a55721304ab7eb |
| budget/assets/categories/magic-box.png | 97c075ad005a452c61b5c0d2d8c06689fc384d096fb841c9de894ee3c13a87ac |
| budget/assets/categories/magnifying-glass.png | 47581100dfd8264c08ddab22340eb3f8e3940e8e75ddd62624d0928e0d991379 |
| budget/assets/categories/make-up.png | 60dae6dc57e44af73c09fd246eb63b2ab4c682255de99911159c75641c0c8085 |
| budget/assets/categories/makeup.png | 7928328a9084c0c57379d172003b0ab7b4939d284d3c7b992dd8b2a1c5d98013 |
| budget/assets/categories/makeup(1).png | a8143215451c862e518707fd101a94e1b3252a41e3ca4cf2840197f47ed3862d |
| budget/assets/categories/map.png | ab347f0e09d5fb039c80fb6b086cfd605ae362c9b96a159a925f62552d8d7a8d |
| budget/assets/categories/media-content.png | 41d94ab0f3f3cea3a915d1f376f44927df90e45fe4a527151cb5f47b3b084d6a |
| budget/assets/categories/microphone.png | 9aa1eb127dd5fd9cb7226bf15a4a9cd05f8c2deb2cf9ac072067cecc3208c182 |
| budget/assets/categories/milk.png | c264ff35fabf207a1b413dc0cc7aeaf768b6e03fa90ffa5f7970d458cf683a70 |
| budget/assets/categories/mixer.png | 12208757c0670000ae63d2ddca72c711e6049b99a4e88c8aea74e73295719dae |
| budget/assets/categories/money-bag.png | 198134f58dccc44d4ab56cdb36bca5bdf046e67950c2675e24f87a8426d11ed5 |
| budget/assets/categories/money-bag2.png | 7d1285ae69fc0ede9ad74f5c044b69da10dcdbd00d28144ffc3d8dff97aca906 |
| budget/assets/categories/money.png | 641857269ef5b2f5638b4e06d280c7278cca1da878d71222ee7aa7185d218c76 |
| budget/assets/categories/motor-bike(1).png | f4b01b4a7b3a62c2d82c986fa3a9a325cd19948206c19c3f80e1e50816f476b1 |
| budget/assets/categories/motor-bike(2).png | d1b3979cc9112ac1f76fdfc955b25ff8f2d4d87fabdeeb756ca9017f32c29c2e |
| budget/assets/categories/multivitamin.png | 12fabbfc6ce6065c3d5b650b21acb645dd8c56f93f9bb684f1bd2624c8408baf |
| budget/assets/categories/music.png | 5cc9dad19fd31a379b8a842e9e04ab4bd8c351cc985521e5a16a411acebb0bcf |
| budget/assets/categories/necklace.png | 129e09f6e77f03c265fcc6bac4ace8a9a5d65481bd46e298881215084572a11a |
| budget/assets/categories/noodles.png | a6b21d0f45314704a49496dbf8a7ef8fc30b98292bc4f36b8ff948f6dea2c656 |
| budget/assets/categories/note.png | 74ac3a89e7a416181925504a52d022db3732e2d0fa4c0d3acd5862c185125d36 |
| budget/assets/categories/oldschool-telephone.png | c2087bd423c4836a23a3ff499d0d338ea440223dc915734a7740cc7b849d95e7 |
| budget/assets/categories/open-book.png | 47223160ade0c099af861e8fc9300a251e2d76bd85b6a2ff1e0aa7150466ef06 |
| budget/assets/categories/open-email.png | 415fa93ccf2a4690381f50e140c599a5d87bdfeb250829e54503d86a596124d7 |
| budget/assets/categories/orange-juice.png | 54119ab5ba6664ba1aaf167f7f6b0521155d852623fc4dd0c6c1ec6a81a22ea5 |
| budget/assets/categories/organic-food.png | 3fa3d63d97c8b370cbd84fbc8bc42fcae621210e484bc854a222832bbcce4c15 |
| budget/assets/categories/package.png | 92c4bc14be27987f0120d0fbea9b92e5f0fe624b268b7229c94ab85ee1f06a33 |
| budget/assets/categories/padlock.png | a9702cdc09e9185a3755fccde47332a12b2e39c3d6e318fb9e12ef5fa19788ca |
| budget/assets/categories/paper-bill.png | cd996fee1ed579bee0b0ffc0aeffa567dbdd0587c2e4bcf35a3558f6902a7551 |
| budget/assets/categories/paper-ticket.png | dfbe344d58a829c5da5e6ba0ec2d171be71a65adb97c17b05569cda5562f0a1e |
| budget/assets/categories/parents.png | 8c5a9a1a9b406fa803a56545073a28a1c98bb795e0bc77cab06cbf98132a5f24 |
| budget/assets/categories/parking.png | 53866c35a6dc3ae25b4fb1fd9ee8d607ca63c466a7519ccd6c6d9aa895540b6f |
| budget/assets/categories/pen.png | 552fbe516aee4ad7d8f1e03d9d1f673a04cf7d30dfe322dd1864b13d61684ea6 |
| budget/assets/categories/pencil.png | 9d85523e38e6aa04803bc7fb8cab37b14d2ed55a8f96d36210f8b8ef6677bcbb |
| budget/assets/categories/pet-bowl.png | 4924afd71fac112327c938289e171aa1fb46123167c409bfe2fe2e741282259f |
| budget/assets/categories/piano.png | 8fe480b396fb79450d97750139c611b122f1fe6279b320eeb703af87f2de0fdd |
| budget/assets/categories/picnic.png | 7884be89ffb7fe6f0b1af53df7dfedd8a2a0d9944139d7e7ab7913deecc89e18 |
| budget/assets/categories/piggy-bank.png | c083d4215c0e535615bfc4d3690c2070556b36595690cbc67c3ec5ef581096f9 |
| budget/assets/categories/pizza.png | 6362ba828da1363a38278d89b007a7766eb5edf62e0b56bf36f3947bf9d65b64 |
| budget/assets/categories/plane.png | 968ee40a7c4a94f43f73090f6e21dc27d2106b91d5c0a8b5e76f84b946ec40b3 |
| budget/assets/categories/plant.png | 32a731cf8418a5f1c292df74645e5a345dd448b78500570112866e05f6251387 |
| budget/assets/categories/popcorn.png | 413555d355f7bb0abb6e646a8ba022aa6a73ef506890dfa81e019bc474fa9d8b |
| budget/assets/categories/popsicle.png | 7caf9c546c023a97af69c99eaceaadec22f9df78fbd68279dfb582591d9f0472 |
| budget/assets/categories/portable-game-console.png | a15f98010756649696e9370ff7549b477d5afda0e636ab05e6da8eb48e24282f |
| budget/assets/categories/price-tag.png | ba232367a3319f7a82e446c6e5e246397a227af7c39de1e11766c062def0e281 |
| budget/assets/categories/pumpkin.png | 477733dde8fe7b6207860d6a2be009b99e55723f1f2a8b02eeb802e09706115d |
| budget/assets/categories/radio.png | bd3c8aca5270b705d44b93bb2ed602888d35dff673f83393f0e332b0f88013fe |
| budget/assets/categories/rain.png | 9c1b0f84ac4bac7b41d25bf0ebf36a47917ff27727522ffea01b629f3c83be97 |
| budget/assets/categories/rainbow.png | 579b0fe2e0989acbec34a6f3aaa203e6d7f7cba0ae627e1764254d6733c3da83 |
| budget/assets/categories/raw-meat.png | 43376610e90bf10f61870605efc3d8f8e96bc8e74fbaf3921f7bfc05b03d6e56 |
| budget/assets/categories/recycling.png | db67021488c9bc4b8d8a9e32bb6f19d8d65953dc7f8602df9183c89dc1e9b007 |
| budget/assets/categories/reload.png | be88926f1d1b4381eaa54f72cecf85219967d423908842a63c89d8c669d61ea7 |
| budget/assets/categories/rent.png | b33fcfa9dcacc3e55befbf788acd772eb377e3907eba503b76296064707799ce |
| budget/assets/categories/robot.png | 4903ff89b7cdb68ff0a96e1848fef0772dfc2075e9c643a69fb2199132cb8cd4 |
| budget/assets/categories/safe-box.png | af0545d93024c7cfb6c9a9bdb057a043033d0299c764d0037da6cfc19fed1024 |
| budget/assets/categories/safety-helmet.png | 134b39caa8cf170de9a90a32d8d10d96e57c3323b6e6fa53f74e3c281c9c2655 |
| budget/assets/categories/salad.png | d5e345cbd2fc8eecfe748f7ffcd7b80f7325feeb6d2acabf5669c400dce20b21 |
| budget/assets/categories/sandals.png | d83c1f3a0338b25c7e8c3c3337421a13b26957332086befa4913ff1c345d93fa |
| budget/assets/categories/sandwich.png | 7c6e45668d88de8f0681bd72ee0056beab3b734af478a0da6059b83084c494d2 |
| budget/assets/categories/sauces.png | 6f6b55575e8ce4a73804e44e3cfb58916383b3c3bdffd7b4ead36deddab12715 |
| budget/assets/categories/school-backpack.png | 57652fb7c52eebabe88945e9b5fde119ab1b143d7bec8504f3aee4ca6320387f |
| budget/assets/categories/school-bus.png | cf9743d4d49eb11f2ca09700dbc7512f89df19ddb6a3e2adccba55cd6f6a3de3 |
| budget/assets/categories/science.png | ffbe7850517874d1da0ce12430acfb596a4dcf048ce21ee2401564d73a60147b |
| budget/assets/categories/security-box.png | f53e90f2e6c355777d7ad4bf6da43028c0e21d8be52cd3d1a8a38955dd8422ff |
| budget/assets/categories/settings.png | 0cf49c4a76f269e429beb2563f86a38ed429352e43883073c1385e8c22a4ba4e |
| budget/assets/categories/shopping-cart.png | 784e40adc0ba04885aa5ca2ac48664c209c98ac044152fa18d110294188aa5ce |
| budget/assets/categories/shopping.png | 2f2529dab9488ac4e64336035ab7b53cfadcc8b697ef9da17e4af97c46df3b0d |
| budget/assets/categories/shrimp.png | 595096b6434973a47468cb0b4f68f7180c4f5a397d3802b142f72152c9f07348 |
| budget/assets/categories/sim-card.png | 8e33f065e2dee4a8397d040d2183480fdc41c71c0de474fe2932eb572181dfba |
| budget/assets/categories/skincare.png | 951397f38151af6ed8bcbe81a19649eb9f826fb28de04d639f473b117736d328 |
| budget/assets/categories/smartphone.png | 53066f58c520b35ffcfb50bce9e30dc18aef65a2329e6e6b8593770ca9e1c596 |
| budget/assets/categories/sneakers.png | f05dc2eb5ffa2362176362a68d1b11d7139ff355597624790f191df67e7bfd1e |
| budget/assets/categories/snooker.png | 337630292b67d6346f3c95d882d1fc107000d2a3780bd9e92bae2b325900675a |
| budget/assets/categories/snorkling.png | 599df6d50f958a55bae2cfaf7e9eefd662e059cc2a0d7f3cc60bda13b678bf8e |
| budget/assets/categories/snowman.png | 9b6f90862da61d94b66fdf256c3333fb5c75fd816e4d5720231fc73d9fdf8755 |
| budget/assets/categories/socket.png | fe77c788dcc92736a919e88613b5ab70ceb4ebe8b63019dd8ffd285acd76b139 |
| budget/assets/categories/spaghetti.png | 3667f208b29111031d214f3ed241bb288753a4057e7bf3c6ff51bfa26c9ef8f5 |
| budget/assets/categories/speaker.png | 171dd8b3b91b3f8604e926e822ff2b969dc66994388bcad4519f53f2394c9094 |
| budget/assets/categories/sports.png | dc85b2f21d929e3d4fcb36d4d10b04b8172094799026072b8653389b30c36b6f |
| budget/assets/categories/sticky-notes.png | ff2b2ac6c59c1394cf9c533d218d0c182679ba67b984cfa1a02e02b213bd2739 |
| budget/assets/categories/subscription.png | 43640acc9728d745b60e890f78742fe7e2569ab631d5be9d5ce791e0a718db1d |
| budget/assets/categories/sushi.png | 1afcc2f023b16bd5e226b793b9c9054f9c1b4ad9b3fb7ab3418a9eb266a2e45d |
| budget/assets/categories/tablet.png | d5e4aafd9cc160c728ab0d4c6b90e7343b75867d3d8cba25a12dda622783168a |
| budget/assets/categories/taco.png | 1018c87eea6ceba5bd43cb26fd4df779077c5c27e781e4bad73c7a8337be20f6 |
| budget/assets/categories/target.png | 7e5bce33efa67741da1e9cbefa1202087591aeed9d1f103d036c911c355d95e2 |
| budget/assets/categories/taxi(1).png | f2bf9d429dc06413f3fe8329cc8c452d1815bfd419d1966d9e7f7b8c338b0771 |
| budget/assets/categories/taxi(2).png | 05948db7abb4e879871a8258bd9d207b48a872e2c4f3b96dfd1ea8bb370b738d |
| budget/assets/categories/tea.png | 525419b4d556f2279c0e4eeedade5614130449693e4cec5d72f966f2f71e92e6 |
| budget/assets/categories/teddy-bear.png | 90b68daabc7a23134c6d02cb5bcfea4eb562a4bf6e7707d7579d34cf6d85996a |
| budget/assets/categories/telescope.png | 320eb5b85c3ec888cc10dbf8e5deb8af8ca09f10ac88dad0b68658613f2019d4 |
| budget/assets/categories/television.png | 26d0e6967085d6bfac7025120ef361ef0daaa1e527a8dcba242b91bbce8470bb |
| budget/assets/categories/theatre.png | 8451c58dfa04269d7e091bb6edfff6905cb95fb8f33486b44a1f67d44bd6a48e |
| budget/assets/categories/tickets.png | df31c7349547507f00f5f7894205c277b29d8530319a8ca6a4db8c77ccf58d8e |
| budget/assets/categories/tie.png | 07905275fea8c17e180d687a03ee66bdbe263c141b16e4406fead55052837ad6 |
| budget/assets/categories/toiletries.png | b4c06314abd96f0090f5d70a8572d96ce5c97a1bc593b6395fcd1535b2af3acf |
| budget/assets/categories/top-hat.png | 988e5477917c09172f476c468622e5d9f9d6aedcd898541270f2d340b81fbab8 |
| budget/assets/categories/tram.png | d9f45d4624d9a459a85c9fd5ecbad2dded55a37be2928467878c0c2fa0b3e42e |
| budget/assets/categories/trash.png | a46796a0334773d78f0b10d70f963083e2c33536fec290192f20bd28031ff74f |
| budget/assets/categories/tree.png | 1f72c388aeff66fb5f881eecfdb81aa350134a9b5d8e7bbb94424cbee67d3320 |
| budget/assets/categories/trophy.png | 882040054d11cb45620100bc3c609b037b53da3f66926d8f397c1367f08d9ce8 |
| budget/assets/categories/tshirt.png | 80bd13d3f6650614f5551fceb921b390ea1eb48e702ea82dae393ac1aac293aa |
| budget/assets/categories/umbrella.png | af150164a562462e1a94525f8535c2e3b559fadb58ac9ae48ae4de2def510947 |
| budget/assets/categories/user.png | 21e14c02f33ee8e87568fb65579a9bcde0c6aeb8d290e0bfde720764d39e4b81 |
| budget/assets/categories/vision.png | 4284a6f24fcef8c88bd51edbdbcdabfa87b52097e2744cd88e02e5619892b375 |
| budget/assets/categories/wallet.png | 2b44db53dc3157e4b5ae8df89369cc628c0364afacb3b290877d8fc193b723a5 |
| budget/assets/categories/washing-machine.png | 99202f7a0eb7dee3664094eaa3100321476902cd1268dec20f534ddb008c09c0 |
| budget/assets/categories/watch.png | 60686951deb8c5f1fb3d31ca58e13a70f11d1eca6f428079c24ba43f29dd87a9 |
| budget/assets/categories/water-bottle.png | 3b8a830b646a4c3895909d7b9211693876c1a446478925a6c802d141ac3b16ab |
| budget/assets/categories/water-tap.png | a1a001201f757914c42274fd81a3916569455b991f5f5b7350aa9f7713ad868c |
| budget/assets/categories/watering-can.png | 25df16c1dd2c06c4b68671279f457c7b4bb7243b010057d6d8c3ffd87a50d09f |
| budget/assets/categories/weight.png | b5707819f647ec0afc8ecfab98eb82ba340e2c3194cf561181de49f6f2e11641 |
| budget/assets/categories/wifi.png | d65bf9336c5a02acd47a8b5bc88b06eb0540355527b1908369840ebc3abfee90 |
| budget/assets/categories/winter-hat.png | ab1c453e167f11c3d9f731c090e78895ce3a233a8e89053422f345e1b7396fa8 |
| budget/assets/categories/yarn-ball.png | 0335638d0c6b26c9f887d22fb88c6347431ba5ab3aa244bb9e12fe7b79bd9db4 |
| budget/assets/fonts/AvenirLTStd-Black.otf | 63c31b44c3953be39a056f29afe090a5aa113862744384d2341c2b2275046a8f |
| budget/assets/fonts/AvenirLTStd-Roman.otf | 79c4a6763cd37a08c07c061494eb890d6703197796f124ed66842cc73dedb5ed |
| budget/assets/fonts/DMSans-Bold.ttf | 9d801f8a966a9860a9fd2921a54362a7d7058c7821e2cafc7f75ed055884a034 |
| budget/assets/fonts/DMSans-Regular.ttf | 1adb096acaa3d14f5ed678e99b808b0c8800f62cb342fa5c276298ad8030b458 |
| budget/assets/fonts/Inconsolata-Bold.ttf | ea7ce405b485b36d65e11fe0269dbe722421eafdb36b5638f338f640fee7cddf |
| budget/assets/fonts/Inconsolata-Regular.ttf | 9d542b954a5ccbf5edd68f240f4a4de9c99acbe3cb4291f0089796e99cddb02e |
| budget/assets/fonts/Inter-Bold.ttf | f9342f2d916aa89c924bc2adcc1d3bfbb6eb54675e48953bacc49024fc768f76 |
| budget/assets/fonts/Inter-Regular.ttf | eeab48280aacd4fc83c1c7e735681df9edd1b59588dde23d0339bcf6552fb788 |
| budget/assets/fonts/Metropolis-Bold.otf | a470d16eb70e97992529479e751032e8cfd0146043d2245ad63d312a6991de63 |
| budget/assets/fonts/Metropolis-Regular.otf | 6f8992eb58eeced41efea7076be4d468ac678f9778420438fab4a3358aa2b462 |
| budget/assets/fonts/RobotoCondensed-Bold.ttf | 9bc003d6f29ab9a6c80c30201c977b07ba01cca926446ddd313d0b7869cab3ef |
| budget/assets/fonts/RobotoCondensed-Regular.ttf | 2af71369b6e1ab597407c5d720ca6e3fcf33554762c14953aa21dbb8667c55f0 |
| budget/assets/icon/icon-small.png | db8ab4d2c36e4b988b714c3179e0c778456ef8dd5f361a8d648957fb1e8788b1 |
| budget/assets/icon/icon.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| budget/assets/icon/notification_icon_android.png | 4143411ae6de9289b27bcba9d70ff6971fc327592a52116f0e26568a3e532dbc |
| budget/assets/icon/notification_icon_android2.png | 33c62b2a4b0563a84436ea720a8afd326f2eb7b5330281c8548dcd72e4277323 |
| budget/assets/icons/fun/party-hat.png | 0ccf0f99625a4d851823b3eda3df24f10fd6eb5861522ad6d63fed0078ea9b1c |
| budget/assets/icons/fun/santa-hat.png | 167ac98d27757aed17efec019215dacc3b3e56802d63c9a4743e3e0f079a5445 |
| budget/assets/icons/Icons.ttf | 0dd01c83f96c00a5a8ec89fde587e98f2c0edae63bf653ba410c4540bcb98d78 |
| budget/assets/images/empty-filter.png | 0a437cd4e9120cd5fde7557b5b94ac7d4cf48d59e4adcfc3c4779133788a8493 |
| budget/assets/images/empty-old-filter.png | 41945ceb68bb033f25422919f11580333c4057c1c429faf38225b61076066298 |
| budget/assets/images/empty-old.png | 9ca082edde40e253ebcdf2610cda3e435f9bb49575d15f7b9285762ce91878f4 |
| budget/assets/images/empty.png | 343548f3b3a9856c686d7ae2689f99797996760b6f05aba3ede11271e4b84f85 |
| budget/assets/images/no-search-filter.png | 35392db06edb1d1aa4da9cda45803f47090bacc4fb082d262cf40ac52aa758f6 |
| budget/assets/images/no-search.png | 78e4a27d5929d36f330d794ca4ccced4e9997e1035058b06336769953da07e8e |
| budget/assets/landing/BankOrPig.png | f2a15b596d31faf8c2dead84b94bd94871bf4d5c6e2a8ed821a90208c0a3b523 |
| budget/assets/landing/DepressedMan.png | f7e6d13ef5823b05fd0cd32e9d76c0477604414c7b34a8a1cb4e19e6c94ffb06 |
| budget/assets/landing/Graph.png | 8037eb08acdffe5c38a4c42c83a2e7ed398ed6e7f30e0d61534fa124fc09e8b3 |
| budget/assets/landing/PigBank.png | ca2654b1096b34ce4c16efa2b3d6f56924f87672fa4bedb7d6b1a0724bdcafbc |
| budget/ios/Runner/Assets.xcassets/addtransaction.imageset/addtransaction.png | e8b683dc1c0cf9ba2fc11fd04d0bcd01b89ac34def31d83fcfb5e8ad700b9342 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20@2x.png | b31b238711275c233008421c9fe5d9118877c4a70c1e7c329efae9c848827402 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20@2x~ipad.png | b31b238711275c233008421c9fe5d9118877c4a70c1e7c329efae9c848827402 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20@3x.png | aa1489e4a22f822d15ec2ce68dbd0dd6048b13652dfb2b1942c1cd59e67a215b |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-20~ipad.png | 09e9f4c3ae09e2983aab92519c0d4ad9a652f964fb220ba4eb1da3af75424bca |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-29.png | c6634be7927d02f62067053866be109ca56e987be7410c257a7517629aa8993c |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-29@2x.png | abb9e6a68732053319f6e9f21b2e510c12335c87066fb43311c1064847e3a494 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-29@2x~ipad.png | abb9e6a68732053319f6e9f21b2e510c12335c87066fb43311c1064847e3a494 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-29@3x.png | 8661d8a397d48c3a93e01d0714cbd93f86892bc5e46724b28f0c8e068791c68e |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-29~ipad.png | c6634be7927d02f62067053866be109ca56e987be7410c257a7517629aa8993c |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-40@2x.png | 8ead41d133634bcba99196ba2508c4455360ef56d077837b3c2abe57c33e9730 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-40@2x~ipad.png | 8ead41d133634bcba99196ba2508c4455360ef56d077837b3c2abe57c33e9730 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-40@3x.png | fa13b5ca1112bc0c68e69af88ff42d370705d9df7fb3ea62623816c5a1b14eb6 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-40~ipad.png | b31b238711275c233008421c9fe5d9118877c4a70c1e7c329efae9c848827402 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-60@2x~car.png | fa13b5ca1112bc0c68e69af88ff42d370705d9df7fb3ea62623816c5a1b14eb6 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-60@3x~car.png | 82c6b40889587a724eaa05994437351052809ad61afe6dc0fe65e3aece2e0a89 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-83.5@2x~ipad.png | 749eb804b009afbbe6ad5a6be82adf35cf82d03a0a779c0f76e193ba0c849444 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon@2x.png | fa13b5ca1112bc0c68e69af88ff42d370705d9df7fb3ea62623816c5a1b14eb6 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon@2x~ipad.png | 9e489a1d336cf34dd7e90971f316c887639d36ac6c34fcaaa2b02fd076594232 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon@3x.png | 82c6b40889587a724eaa05994437351052809ad61afe6dc0fe65e3aece2e0a89 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon~ios-marketing.png | 64ad443a6377f04d242bb041c25a5d2de05d756f67951b20216642fa8f667b46 |
| budget/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon~ipad.png | 41e87f16bb14939b80789e8ffcde21c46b959379a3cde0512b975a0640a62197 |
| budget/ios/Runner/Assets.xcassets/LaunchImage.imageset/icon 1.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| budget/ios/Runner/Assets.xcassets/LaunchImage.imageset/icon 2.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| budget/ios/Runner/Assets.xcassets/LaunchImage.imageset/icon.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| budget/ios/Runner/Assets.xcassets/piggybank.imageset/piggybank.png | 44465d0813fe016e4270d8ed8787530e663f5340417be24222e087335a91abc2 |
| budget/ios/Runner/Assets.xcassets/transfertransaction.imageset/transfertransaction.png | b868716052ceded7908cbf2802e657923f118bd18fa46934d2e0d977778ba423 |
| budget/packages/implicitly_animated_reorderable_list-0.4.2-modified/assets/demo.gif | 91d37606002681127b010e91bc3c714d2da100572cf680d5779843d0176981f9 |
| budget/packages/implicitly_animated_reorderable_list-0.4.2-modified/assets/min_demo.gif | 0112d5c5a1ef719c88fd4690ed307536c15607a9b4217bed1472a5f9c16bc1c5 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example_header_footer.gif | 5b18f830f11ce52ceb976250508306a7899ce7e72d1eed49d44882321a1c0eee |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example_reflecting_changes.gif | bb85b8175decb1464947fcb7e388cc67ef7899f50a4c501bbe159f85f9783184 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example_snapping_pixelOffset.png | 9da899bfa83ad7d07953493b4f6576a0656de8b610949772685069d0912fafd8 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example_snapping_relativeToAvailableSpace.png | cd8f55e732332af7991d550de5250c2945b691fa6b185f1f1f788bfebdf81ff3 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example_snapping_relativeToSheetHeight.png | 8b909409951d6a81a32a38193cd2616f3ef017b0596ec1f382ef04f7a533a6f1 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/example.gif | e4bcbd7206259ceb1a1feab99e631707b9ba386e6108cd433a240e8c5dc43ce4 |
| budget/packages/sliding_sheet-0.5.2-modified/assets/non_dismissable_demo.gif | 72162173770b7e52bfb0a2ed5ddc3b191d30b2eecedacfd2c91f28840243b53a |
| budget/packages/sliding_sheet-0.5.2-modified/assets/parallax_demo.gif | 1b8beaa148cb75f2cc743a7e8e1faf1d019bbdf72d95a7e5fb0f4c9c3d6f58fc |
| budget/packages/sliding_sheet-0.5.2-modified/assets/usage_example_bottom_sheet.gif | b47bd6cc12f530a88eaa3d768b5ac58137006979840db5a4cb60511748fc142d |
| budget/packages/sliding_sheet-0.5.2-modified/assets/usage_example.gif | 96513eeb9fa0acbcde0c39bf2fff8b52eb71174ee7364a6886a17efb7fd8de42 |
| budget/web/favicon.ico | 057f44a07d3a9aaeaaf0ff8d463f53de7fc82fbd0c00e7f1e2873dc359cb74f6 |
| budget/web/favicon.png | 5e725829c2e8ffe39c2b1e284ec89eac77c2c4ea0038b598ded01e2e3e3e77c5 |
| budget/web/icons/Icon-192.png | 095903cd2a5b681e5d57a9206e9507175f54bf0364e73ced98f0be7559844a2b |
| budget/web/icons/Icon-512.png | 660daccd892bc336dd64eb6862cba6540da96a52e9230ceea0312fb61b2e46c3 |
| budget/web/icons/Icon.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| promotional/AppStore/iPad/Tablet Frame 1.png | ab5e5a0d6edb6302e43f17db5e8219ffa74a883a64170417d5c3360d953a9881 |
| promotional/AppStore/iPad/Tablet Frame 2.png | 5924d5b9e63198521cc340ee709cd4461d15941b252f08af2bebd5b3ffcc9281 |
| promotional/AppStore/iPad/Tablet Frame 3.png | 2b2f0ed855a10dc4684d38984fdb2551e9c89061c542ed6c80bf383befc38e22 |
| promotional/AppStore/iPad/Tablet Frame 4.png | 1b65eae68362b15851998a4e4265ccd0ec53918186a2a9e110e61e92df72fd64 |
| promotional/AppStore/iPad/Tablet Frame 5.png | dcf0f8f5b47f4265e670bcd83ee4d08e4362ec744c5bb234ddde37ef1e382b0a |
| promotional/AppStore/iPhone5.5/Frame 1.png | 19120caf6b8c4cdeef421e87f2c05b4e3f3d5105d22d1234e3c67c2125540479 |
| promotional/AppStore/iPhone5.5/Frame 2.png | 19ceb253e1230cbbb6df08a575f59d04949954aeaba312458c4918f36e774e78 |
| promotional/AppStore/iPhone5.5/Frame 3.png | a7a89548bf453c76485aad51c7d5ffa0e55b2e61f9602d194e4f67b2bb5257ba |
| promotional/AppStore/iPhone5.5/Frame 4.png | fb9b7200a2e50577d1d2ef4b45d84ad72ca6e4959759ffbe1b12c927fecdc4bb |
| promotional/AppStore/iPhone5.5/Frame 5.png | 44495eea91bfffe0e3c87341ae0556f42dcfd4a1a14f7ec077e52424722f3558 |
| promotional/AppStore/iPhone5.5/Frame 6.png | 652ae74df1e4f7419833089383d2a925c979a1c25a42114e39568a170ad1bdcb |
| promotional/AppStore/iPhone6.7/Frame 1.png | 55e0318ae2a1227b4851575ec7f0cd31cbf08ab89ed2029d208e3847438965e5 |
| promotional/AppStore/iPhone6.7/Frame 2.png | 3e4ddd31844b512a29fba54b5d67ecad8981ace27293cf093c2bc573f3bcfdb6 |
| promotional/AppStore/iPhone6.7/Frame 3.png | fafc925385d95bce7adb4ba268e750f19a7ad2d99e99c836fa7a94ac013d638a |
| promotional/AppStore/iPhone6.7/Frame 4.png | 493e21a85cf74588f559bf51e1bdf77bea8aece6034265a22ac5b1659cac9fdc |
| promotional/AppStore/iPhone6.7/Frame 5.png | c3c5307c9b958200cfa753f17b510e4aed174db755e2dad67104dea57675106e |
| promotional/AppStore/iPhone6.7/Frame 6.png | 3e6b914532a1358b04b70a153474b9399cd026cc47d9737f628e40fc0b730934 |
| promotional/GitHub/SocialPreviewGitHub.png | 4e7496ab1dc1ab336af3531892caa4ab9fbd91a972fd3545cb7f240c8a37feee |
| promotional/icons/icon-opacity-bw.png | d56e47cb6a291fb826d209b24571172d5729e101ef2b529da9450443c54752a3 |
| promotional/icons/icon.png | e2b8b9332a2edbacebf574fac4e978b5056cae3170dab53ded2ea30823adb8bc |
| promotional/material-apps-feature/material-apps-feature.png | dbf43c879e59a51616b647099393678fc30ed42baaf0ab70c6236ffb7c108110 |
| promotional/play-store-feature/play-store-feature.png | acc8261367b706414fea2c60f8138956a78e43f5d5efa2b9395eff0a4554cd39 |
| promotional/play-store-feature/play-store-feature2.png | f1d72842a7d3a8c7c124c16e0ab6f4de7fa0ad549f3701897a8f663bd79467d2 |
| promotional/PlayStore/Chromebook Screenshots/Chromebook Frame 1.png | 9a468b5a3ec3b2b3b24d20aeaafe16e1f8afc9ed5cbb54621e0f9e6922aa27ca |
| promotional/PlayStore/Chromebook Screenshots/Chromebook Frame 2.png | 38b7d906808a1c4674b8354ce62ba047b8769dd9851736868b54ffc5a7dd0ba1 |
| promotional/PlayStore/Chromebook Screenshots/Chromebook Frame 3.png | c9d5e24575a5fe91dcdad6e737719d072d2f274fdef5d3448b3884e598033e9b |
| promotional/PlayStore/Chromebook Screenshots/Chromebook Frame 4.png | 1a0f4b0b576730179352bac9144085db02c2b1775bd4c47bf1788d37c5ac3e54 |
| promotional/PlayStore/Chromebook Screenshots/Chromebook Frame 5.png | d0dd95b82938b5bfbd9af3c1d741abfc9c533640fa013071534e89d53e296e43 |
| promotional/PlayStore/feature-graphic-old.png | 7f5960939b1382c3aef30842eeea1bf1d7743eeeeefdbbd3ae8954b05faa7e29 |
| promotional/PlayStore/feature-graphic.png | a3dd5511f40e7677507dda058bd7d961ac87805ba400894ed2ed0779739dc8d3 |
| promotional/PlayStore/icon512.png | d4147e65dc62a68a77b0a85f9f7a7a776fb24f4bb970ce6a394776684e109c34 |
| promotional/PlayStore/Phone Screenshots/Frame 1.png | a10c3c533f494d7b8763496bb96388d039a3c4ff1d43e516c62ca3f19a6755ee |
| promotional/PlayStore/Phone Screenshots/Frame 2.png | 66ced01aab809315ecbd18947a51ee9e143fcd5d1accdc699e00966e87508f32 |
| promotional/PlayStore/Phone Screenshots/Frame 3.png | b65b68620d6a47be1656a253fcf51853969a2151aaa256bd09b6c88a3f54da3d |
| promotional/PlayStore/Phone Screenshots/Frame 4.png | c668d9bcd8fd8108155a291e0432158306f969b53ba59e16591f1f9f9800c142 |
| promotional/PlayStore/Phone Screenshots/Frame 5.png | 9b05513a73f44deec45560815799642009be2983132093e8a7ff76f52988dc1a |
| promotional/PlayStore/Phone Screenshots/Frame 6.png | 85a83a1693303b2f331d0e85c6c3e4e99cee16acb60e26665797e382b993a94b |
| promotional/PlayStore/Side Tablet Screenshots/Side Tablet 1.png | 110638fcef342e07f8328eda4e746223149e81cc9cfbc4e5ba85b592ec5e7945 |
| promotional/PlayStore/Side Tablet Screenshots/Side Tablet 2.png | 57ad22c86c75d980189e24a5fcbb6470bce344cfdcaa1b29cb886b5b6119f10f |
| promotional/PlayStore/Side Tablet Screenshots/Side Tablet 3.png | 009b0acb19669ea97e8f9840ad1f66656610f0caa09de07d52dd8ef7ce4aa68e |
| promotional/PlayStore/Side Tablet Screenshots/Side Tablet 4.png | 5830e3feae4315aaddc2c462a6b962e8f9b7dfe101e2ee807d2c24427c9e1d8e |
| promotional/PlayStore/Side Tablet Screenshots/Side Tablet 5.png | efbcc443b93542d3429af547478b0f60d4099d75ae00d865fd2e49aa95eda0b4 |
| promotional/PlayStore/Tablet Screenshots/Tablet Frame 1.png | 99e61b04d4c1b7eb2aadbe3ff0f264b23bb898022565bd6591b6d24a66ba768d |
| promotional/PlayStore/Tablet Screenshots/Tablet Frame 2.png | dc0b723c8d1979a4002ce842eccf99dc5282a5fd9e6eee92417cb83466300412 |
| promotional/PlayStore/Tablet Screenshots/Tablet Frame 3.png | ba333fcb3ad41622172ddc1cf691ea53afc39750567eda3e4804a621282c1d01 |
| promotional/PlayStore/Tablet Screenshots/Tablet Frame 4.png | 256d12ca0937b5f047c1ec92d22848420ec0de66e488a60b991162fbae5c9c6c |
| promotional/PlayStore/Tablet Screenshots/Tablet Frame 5.png | 3c083c4792108e93bc799195f02cf0b3fae4da8b0da1458d5a1f344f53996aaa |
| promotional/store-banners/app-store-badge.png | 70a8996c164b91f67b9b9674b9824f4b9f88e9fdf9f8f5fd537d1c4b9462c516 |
| promotional/store-banners/github-badge.png | 4eff328c1149b3b961013040ad7ad2bac98ec0ca8ef64dca14c42738789f315a |
| promotional/store-banners/google-play-badge.png | 1fd9568cc00ab227e030075f84432fa4eed0565b621283d3bca70126f7ccc526 |
| promotional/store-banners/pwa-badge.png | 7faf9690fc73526fa3ee4f048f4c9180f07fa680da71cfacf9844a44b908d5b3 |
| promotional/youtube-promo/playbutton-overlay.png | 9b8f275df389faebd64c43d6ef8bff7391d599f6109ebbf30d67353936dffaa2 |
| promotional/youtube-promo/thumbnail-oss.png | 28d365eb5fa6af9f40714ef4b76d51f5bfdcc86491e0e835ee971a6446e88898 |
| promotional/youtube-promo/thumbnail-year-best.png | 453df66097fc6dd2024692ad306fc42b611d92a7355f0a99565fbb1f03651f94 |
| promotional/youtube-promo/thumbnail.png | aec34daf259b7fd99e99b1fd129bfedf97930899794b1259238efa86714d9f72 |
| budget/assets/static/Convert.py | 56676c7c1d8ee79e60e723d69f1863a2c18f416e38c004b67bcb4c455c627587 |
| budget/assets/static/countries.json | d6ef51849aa8f50da56af91bc88357ea8c8d17d6aca2d6cb34f47a325ab99313 |
| budget/assets/static/currencies.json | 506892847ca7c0f1f989cc0a74de29ab181291840a4c2a3904adf488304af310 |
| budget/assets/static/currenciesInfo.json | a402c08916bcb69195f3165c3070fd039677be033963d26049136a45d7a9926b |
| budget/assets/static/currenciesInfo2.json | 8c9a6dc4764687ef1fc0b53ec56a51428ad1b00dcf43ad1926e2a61bafcd2253 |
| budget/assets/static/language-names.json | 071cd64f71702917f6590501bfaf8fa58cc58545c6de5ffb4a4278183aeedac0 |
| budget/assets/static/README.md | b730e5b81e9450463c307520dcd2aec81aa60803e33444b2b87d305173e97243 |
| budget/assets/static/generated/currencies.json | 16469269ba702e538b63467cc4c7bb380730d92c33ed938d3fbefac7889083e6 |
| budget/lib/pages/aboutPage.dart | 4f70188bfd8ac892bb9cc4ecc2177f448f9067c1ecc66003c3fb03fced7d860b |
| budget/pubspec.yaml | 1dcc4e40416370eacd22b7c57e2a2c385e6613f37a8b5942832c1b5966536c48 |
| budget/assets/translations/generated/en.json | 97f9d3a51c3df2e21cdfbbd814c887e0180085bde09bab54f68ea55995000b3c |
| budget/lib/struct/currencyFunctions.dart | f5ef6c25804c935263ea45530dec2fc79e2af996a4d3d21de1326af4e450a956 |
| budget/lib/struct/languageMap.dart | 7d18b4db2e62c23a15edfc284050016dbfdeb7e6df419bdf4c9f86d1b2da6679 |
