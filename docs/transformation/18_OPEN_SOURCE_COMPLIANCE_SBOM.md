# Phase 2A — Open-source compliance and SPDX SBOM

## Status and scope

The repository now has an initial implementation-ready open-source compliance architecture. It inventories committed dependency inputs, emits a deterministic SPDX 2.3 JSON SBOM, preserves Cashew/GPL provenance, and blocks a release manifest that lacks source mapping, artefact hashes, notices, rights clearance, store review, or human legal approval.

This phase did not alter application runtime behaviour, UI, financial logic, Drift schema, Firebase configuration, product branding, or infrastructure. It does not declare the product legally cleared for release.

## Reproducible inventory

The canonical outputs are:

| Artefact | Purpose |
|---|---|
| `compliance/sbom/current.spdx.json` | SPDX 2.3 JSON document with packages, checksums where available, and dependency/containment relationships |
| `compliance/inventory/current-components.json` | Full normalized component records, summary, and unresolved audit gaps |
| `compliance/reports/current-components.md` | Human-readable generated inventory |
| `compliance/components/non_pub_components.json` | Reviewed non-Pub inputs and explicit gaps |
| `compliance/provenance/cashew-upstream.json` | Cashew source/licence/history/remote evidence and ownership boundary |
| `compliance/release/release-manifest.template.json` | Fail-closed template for release-specific evidence and approval |

Each component records an identifier, name/version, ecosystem, direct/transitive/root/build-tool/asset relationship, distribution and modification status, licence conclusion, evidence, source repository or resolved path/revision where available, checksum where available, and review status. A `NOASSERTION` value is an explicit unresolved-evidence state. It must never be interpreted as permission, prohibition, public domain, or absence of a licence.

### Current results

| Ecosystem | Components |
|---|---:|
| Pub/Dart | 236 |
| CocoaPods | 55 |
| Maven | 12 |
| Application, toolchain, Gradle, vendored/generated/web, assets, fonts and datasets | 21 |
| **Total** | **324** |

- 280 components are currently classified as distributed.
- 11 are identified as modified or forked.
- 82 require licence review and are recorded as `NOASSERTION`.
- Pub licence evidence resolved locally to 161 BSD-3-Clause, 52 MIT, 18 Apache-2.0, 6 MPL-2.0, and 2 BSD-2-Clause records; the additional BSD-3-Clause records include toolchain/manual entries. The three GPL-3.0-or-later records are the application, translations, and generated translation source.
- The SPDX document contains 324 unique package identifiers and 898 valid relationships.

The inventory distinguishes direct runtime, direct development, transitive, build-tool, root, bundled asset, source-only, and related component roles. Pub runtime reachability is computed from committed Pub metadata. CocoaPods are represented from the committed lock, while their licence evidence remains unresolved. Android direct coordinates are represented, but the repository currently lacks a complete locked release-variant transitive graph.

## Cashew provenance and GPL boundary

The source-of-truth provenance record identifies:

- upstream project: Cashew;
- upstream repository: `https://github.com/jameskokoska/Cashew`;
- licence: GPL-3.0-or-later;
- original notice: `Cashew: an expense budget tracking application; Copyright (C) 2023 James Kokoska`;
- relationship: modified fork;
- upstream remote: fetch-only, with pushing disabled;
- root licence: retained and verified using its filtered Git blob identity plus exact GPL text assertions;
- Git history and tags: retained.

ÓLA HEDGE FINANCE may identify its original modifications and additions, subject to contributor agreements and applicable law. It must not claim authorship or ownership of original Cashew code merely because the fork is rebranded or modified. Existing original notices and legally required provenance are distinct from removable product branding.

For each binary distribution, the release owner must provide the complete Corresponding Source for the exact shipped version, including modified source and the scripts or other material needed to control compilation and installation as required by the applicable GPL terms. The binary, source archive, immutable tag/commit, SBOM, notices, and published source location must agree. The chosen distribution channel and source-delivery method require qualified legal review; this document does not decide whether a written offer or another mechanism is sufficient for a particular launch.

## Generation and automated gates

From `budget/`, after dependency resolution with the pinned toolchain:

```text
flutter pub get --offline
dart run tool/compliance/generate_sbom.dart
dart run tool/compliance/generate_sbom.dart --check
dart run tool/compliance/release_compliance.dart
flutter test --no-pub test/compliance
```

The generator is deterministic for unchanged committed inputs and resolved licence evidence. Audit mode verifies:

- canonical artefacts are not stale;
- inventory and SPDX counts/relationships are structurally consistent;
- each unresolved licence has visible review evidence;
- every audit gap has a release gate and required action;
- the root GPL text, Git blob, original notice, and provenance assertions remain intact;
- `origin` identifies the ÓLA repository;
- `upstream` identifies original Cashew and is push-disabled;
- history and tags remain available.

For an actual release, generate `compliance/sbom/<version>.spdx.json`, copy the release manifest template, record only real evidence, then run strict mode:

```text
dart run tool/compliance/release_compliance.dart \
  --release-manifest ../compliance/release/<version>.json
```

The committed template intentionally fails strict mode. It is not a pre-approval. Strict mode requires a clean tagged commit, real HTTPS Corresponding Source URL, existing source and binary artefacts with matching SHA-256 hashes, a version-specific SBOM, notices, GPL source review, asset/font clearance, store-terms review, and a named/date-stamped legal approval.

## Audit gaps and release gates

| Gap | Affected release | Required action |
|---|---|---|
| Android transitive resolution is not committed | Android | Generate and review the release-variant dependency graph/licence report on the Android build host; add resolved components before release. |
| CocoaPods lock lacks licence texts | iOS | Resolve pods on macOS; retain podspec/licence evidence, generate notices, review, and regenerate. |
| Bundled SQL.js identity/provenance is incomplete | Web | Identify or reproducibly rebuild the exact JS/WASM artefacts; record version, source revision, build recipe, licences, and notices. |
| Font redistribution evidence is absent | All public binaries | Obtain source/acquisition/licence evidence or replace the fonts; have a qualified rights reviewer clear them. Avenir is a priority risk. |
| Image/icon rights manifest is incomplete | All public binaries | Record author/source/licence per asset and replace or remove unclear assets. |
| Bundled dataset provenance is incomplete | All public binaries | Pin sources, confirm content/database rights, document transformations, and retain attribution. |
| Fork delta/modification notices are not centralized | Corresponding Source | Record upstream and fork revisions, patch provenance, and required modification notices for each local/Git fork. |

Additional platform-specific evidence must be refreshed from the exact release build environment. The inventory must also be regenerated whenever lockfiles, dependencies, bundled assets, toolchains, or local forks change.

## Release operator checklist

1. Confirm the release tree is clean and based on the intended immutable tag.
2. Resolve the applicable gaps above; do not convert `NOASSERTION` to a guessed licence.
3. Regenerate current and versioned inventory/SBOM artefacts and review their diff.
4. Produce binary artefacts and a complete Corresponding Source archive from the same commit.
5. Exclude credentials, signing secrets, private Firebase configuration, and other production secrets from public source artefacts; confirm that excluding a secret does not omit required build/source material.
6. Generate/review third-party notices and preserve the root GPL and original copyright/provenance notices.
7. Record SHA-256 hashes, platform, commit, tag, version, published source URL, and exact artefact paths in the version-specific manifest.
8. Obtain product-owner and qualified legal review for GPL delivery, asset/font/data rights, third-party terms, and Apple/Google/web distribution terms.
9. Run the strict gate and archive its output with the release record.
10. Publish binaries only after the source and notices are available through the approved mechanism; retain the evidence for the required period determined by counsel.

## Owner and legal decisions still required

- name the organization/person responsible for open-source compliance and release evidence;
- approve the Corresponding Source hosting and retention mechanism;
- decide contribution and copyright-assignment/DCO policy for new ÓLA changes;
- clear all fonts, images/icons, datasets, vendored SQL.js files, and modified package deltas;
- commission platform-specific dependency/licence evidence from Android and iOS release hosts;
- determine required third-party notices and source/modification notices;
- obtain qualified GPL and app-store distribution advice before commercial/public release;
- define how users and recipients can find the source, licence and notices from each distribution channel.

## Architectural conclusion

Phase 2A is architecturally established: the repository has a deterministic initial SBOM, an explicit evidence inventory, preserved provenance, tests, and a fail-closed release gate. It is not release clearance. Public distribution remains blocked by unresolved native/asset/font/data/vendored-source evidence and by the intentionally incomplete release-specific manifest and legal approvals.

