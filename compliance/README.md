# Independent compliance reconstruction — 2026-10-09

This is an **independently reconstructed technical evidence baseline**, not a release clearance. Remaining release gaps keep Phase 2A incomplete. Historical checkpoint `7f3209eebb270aaef11d875c0d214467619a0627` remains **NOT RECOVERED**. The native supplement `48959137a32d9ff8c4a02c6b4707539b858e1ef1` was unavailable in the inspected object databases; none of its claims was accepted as recovered evidence.

The starting source is canonical `develop` at `eb4adf8b6b8d8117bdf5f9ffa7288c6e42e3e94f`. Work is isolated on `compliance/reconstruct-verified-baseline-2026-10-09`. Reconstruction commit `d87469876b8f61f134371a549c3982bb47651082` preserved application source. Its dedicated follow-up corrects only inherited native identities using the surviving owner-approved matrix and required native routing/configuration. Dependency versions, asset binaries, Firebase configuration, deployment workflows and long-lived branches remain unchanged.

## Surviving evidence and reconstruction method

The generator, parser, release gate, three original test files, policy and input schema were ported selectively from surviving Git commit `6a8a37668ce6b34761026e8594ae80a55ec2b851`. Its generated SBOM and historical counts were not imported. The new generator re-reads the current Pub lock, package metadata, Podfile lock and current reviewed input manifest. Original source provenance remains in `provenance/cashew-upstream.json`; GPL history and copyright remain unchanged.

Current evidence lives in `evidence/reconstruction-2026-10-09/`:

- `pub/manifest.json`: 236 current Pub package notice records. Every hosted archive was freshly downloaded from its exact version URL, SHA-256 checked against the lock and its retained metadata/notice bytes compared to the cache. Git/path/SDK entries have separately described narrower provenance. Full retained licence/NOTICE/AUTHORS texts are linked from `../legal/THIRD_PARTY_NOTICES.md`.
- `native/native-wrapper-cache-inventory.json`: 25 newly rebuilt wrappers, including 24 authenticated hosted archives and the exact clean `file_picker` Git revision. Locked Pub versions, static pod versions, source and target hashes are distinct. No CocoaPods checksum replay or native SDK/transitive clearance is asserted.
- `maven/manifest.json`: ten exact-coordinate POMs. The app's declared Firebase BoM 31.1.1 and wrapper default 33.1.0 are unresolved until a release Gradle graph establishes the actual selected versions. POM licence declarations are conditional metadata evidence, not native binary clearance.
- `sqljs/provenance.json`: npm SQL.js 1.6.2 archive integrity verified, WASM byte-identical, JavaScript equivalent only after CRLF normalization; exact source commit, Makefile, contributor instructions and licence/authors retained. A from-source Emscripten build was not run.
- `asset-dataset-investigation.md`: 437 freshly hashed design files with conservative classifications and embedded font metadata. No reported historical font/icon replacements were recovered. All remain blocked pending rights evidence; two Avenir files require license-administrator/counsel review.
- `dataset-reproduction.json`: surviving `Convert.py` regenerated currency JSON byte-for-byte in a separate directory. This proves the current transformation, not rights to its inputs. Currency/language terms and source revisions remain incomplete.
- `evidence-index.json`: hashes current source inputs and retained evidence. The generator rejects missing or modified indexed bytes before regeneration. Evidence payloads retain exact bytes via `.gitattributes`; source-input hashes describe this Windows checkout's line endings.

The SPDX graph describes the current source/lock inventory. It does **not** purport to be a complete resolved Android/iOS binary graph. Missing native relationships, platform selection and dynamic dependencies remain gaps. Counts must be read from the newly generated files, never used as target numbers.

## Verification and release gates

Use preserved Flutter 3.19.6 / Dart 3.3.4, current unchanged lockfiles and the resolved Pub cache. From `budget/`:

```text
flutter pub get --offline
dart tool/compliance/generate_sbom.dart
dart tool/compliance/generate_sbom.dart --check
dart tool/compliance/release_compliance.dart
flutter test --no-pub --concurrency=1
dart tool/compliance/release_compliance.dart --release-manifest ../compliance/release/release-manifest.template.json
```

The final command is an expected rejection of an incomplete template, not a passing release test. The gate now rejects every unresolved gap and every distributed conditional/unverified component even if a manifest asserts approval. Regression tests cover that rejection, the canonical origin spelling and changed retained notice bytes. The original repository-audit failure was independently reproduced: inherited identifiers in ten Android/iOS files. The dedicated identity remediation applies the existing owner-approved environment matrix from `53024f373b3cb66eb3e7c13d0f2afbe41a8a3287`, removes the unowned Apple team, and strengthens the audit rather than exempting shipping files. `application-identity/` under the evidence directory records the full pre-edit occurrence inventory, source decision and deferred platform setup. New regression checks cover namespaced Android widget lookup and matching CocoaPods configuration imports.

On this host, the Flutter batch wrapper failed its Git PATH probe. The same preserved SDK's `bin/cache/dart-sdk/bin/dart.exe` and `bin/cache/flutter_tools.snapshot` were used directly. The test process adds the preserved SQLite DLL directory to PATH. Android/iOS release builds are **NOT TESTED — ENVIRONMENT BLOCKER**: no Android SDK/Java or macOS/Xcode/CocoaPods build environment was available.

## Corresponding Source and notices delivery

The full-history preservation bundle contains this source tree and its committed evidence. It is **not** a complete release Corresponding Source package: exact binaries, immutable release tag, build/install environment, native resolved source graph, four fork deltas, full notice delivery and approved delivery URL remain unverified. Pub archive URLs/hashes, Git revision IDs and vendored source paths are reconstruction inputs, not proof that a recipient can rebuild a released binary.

No app notice bundle was changed. Repository-retained texts must be integrated and tested in the eventual released artifact under a separately reviewed change. Asset/font licences are not inferred from family names; custom icon source mapping/rebuild remains unresolved. Figma authorship/editable history and AI-generated asset provenance were unavailable; no ownership or clearance is asserted.

The eight remaining release gap groups are Android resolved graph; CocoaPods/native licensing; SQL.js release source/notice delivery; font rights; image/icon rights; datasets; fork deltas; final third-party notice compilation. Qualified legal review remains required for GPL source delivery, store terms, proprietary font rights and ambiguous data/design rights.

The owner explicitly permits `compliance/verified-reconstruction-2026-10-09` only as an evidence-only checkpoint after technical checks pass. The strict release gate must continue to reject unresolved gaps; the tag is not release/legal clearance or recovery of the missing historical checkpoint. Consult the external checkpoint manifest for the exact commit, executed checks, bundle hash and untracked-report exclusions. Native builds remain untested, platform registrations/signing remain deferred, and the unchanged Podfile lock checksum requires real CocoaPods reconciliation. Keep Phase 2A incomplete; no push or Notion update is authorised.
