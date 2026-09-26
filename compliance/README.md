# Open-source compliance package

This directory contains the initial, reproducible software-bill-of-materials (SBOM), component/licence inventory, Cashew provenance record, and release-compliance gate for the ÓLA HEDGE FINANCE fork. It is engineering evidence, not legal clearance or a substitute for qualified legal review.

## Canonical files

- `sbom/current.spdx.json` — SPDX 2.3 JSON for the current repository inputs.
- `inventory/current-components.json` — normalized machine-readable component inventory and audit gaps.
- `reports/current-components.md` — human-readable inventory generated from the same model.
- `components/non_pub_components.json` — reviewed native, toolchain, asset, data, vendored, and locally modified component inputs.
- `provenance/cashew-upstream.json` — upstream Cashew identity, GPL provenance, ownership boundary, Git-history expectations, and release rule.
- `release/release-manifest.template.json` — deliberately incomplete release evidence template. It must not pass strict validation until real artefacts and approvals replace every placeholder.

Generated files must be changed through the generator, not hand-edited.

## Reproduce and check

Prerequisites are the repository-pinned Flutter/Dart toolchain, an already resolved Pub cache, and the committed lockfiles. From `budget/`:

```text
flutter pub get --offline
dart run tool/compliance/generate_sbom.dart
dart run tool/compliance/generate_sbom.dart --check
dart run tool/compliance/release_compliance.dart
flutter test --no-pub test/compliance
```

The generator consumes `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`, `components/non_pub_components.json`, `provenance/cashew-upstream.json`, and resolved Pub package licence files. For unchanged inputs, repeated runs are byte-for-byte identical. `--check` exits non-zero when committed generated files are stale.

The default release-compliance command is repository audit mode. It checks generated-artifact freshness, SPDX/inventory structure, unresolved-evidence accounting, the root GPL text and Git blob, provenance, remotes, history, and tags. It does not claim that a binary release is cleared.

## Release-specific workflow

For each proposed version:

1. Create a version-specific copy of the template under `compliance/release/` and replace all `REQUIRED` values with real evidence.
2. Build from the exact clean commit that an immutable release tag identifies.
3. Generate a versioned SBOM: `dart run tool/compliance/generate_sbom.dart --version <version>`.
4. Package the complete Corresponding Source for the binary, including modified source, build/install scripts, dependency inputs, licence/notices, and this compliance evidence. Do not include credentials or private production configuration.
5. Hash the source archive and every binary artefact with SHA-256 and record their repository-relative paths and hashes in the release manifest.
6. Review third-party notices, font/asset/data rights, platform/store terms, the proposed source-delivery mechanism, and any written-source-offer implications with qualified counsel.
7. After the human approvals are recorded, run:

```text
dart run tool/compliance/release_compliance.dart \
  --release-manifest ../compliance/release/<version>.json
```

Strict mode rejects a dirty or mismatched tree, placeholder or malformed metadata, absent versioned SBOM, invalid Corresponding Source URL, missing artefacts/hashes, and incomplete human/legal gates. Passing it is necessary engineering evidence, not a legal opinion.

## Current snapshot and known gaps

The initial snapshot records 324 components: 236 Pub packages, 55 CocoaPods entries, 12 Maven entries, and 21 application/toolchain/Gradle/vendored/web/asset/font/dataset entries. Of these, 280 are marked distributed and 11 modified or forked. Eighty-two records remain `NOASSERTION`, meaning evidence is missing or ambiguous—not that no licence exists.

Before any affected public binary is released, resolve the seven recorded audit gaps:

- obtain a resolved Android release-variant transitive dependency/licence report;
- retain and review CocoaPods podspec/licence evidence on the iOS build host;
- identify or reproducibly rebuild the bundled SQL.js artefacts and record source, version, build recipe, and notices;
- clear or replace bundled fonts, especially Avenir;
- create source/author/licence manifests for distributed images and icons;
- pin and clear bundled currency/language dataset provenance and transformations;
- record the exact upstream-to-fork delta and modification notices for local/Git forks.

## Provenance and ownership boundary

ÓLA HEDGE FINANCE is a modified fork of Cashew. The repository retains the root `GPL-3.0-or-later` licence, the original Cashew copyright notice, Git history and tags, and a fetch-only `upstream` relationship. Rebranding does not transfer authorship or ownership of original Cashew code. ÓLA may identify its own original modifications and additions, subject to contributor agreements and applicable law, without claiming the original Cashew work.

Every distributed binary must be mapped to exact Corresponding Source and an immutable revision/tag. The root GPL, original notices, third-party obligations, and any required modification/source notices must remain available. Platform distribution terms and the actual source-delivery method require release-specific legal review.

