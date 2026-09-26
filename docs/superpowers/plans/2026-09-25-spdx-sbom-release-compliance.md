# SPDX SBOM and GPL Release Compliance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reproducible SPDX 2.3 SBOM, licence/component inventory, upstream Cashew provenance record, and automated release-compliance checks without changing application behaviour.

**Architecture:** A dependency-free Dart library reads the committed Pub and CocoaPods locks plus a reviewed non-Pub component manifest, inspects locally resolved Pub licence evidence, and emits deterministic JSON/Markdown artifacts. A separate release checker validates GPL provenance, generated-artifact freshness, unresolved-evidence accounting, and release-manifest requirements. Human documentation records audit scope, known gaps, and the release procedure.

**Tech Stack:** Dart 3.3.4 standard library, Flutter 3.19.6 test runner, SPDX 2.3 JSON, JSON source manifests, Git.

**Spec:** `docs/transformation/06_LICENSE_REVIEW.md` and `docs/transformation/14_INFRASTRUCTURE_SEPARATION.md`, as refined by the owner-approved Phase 2A task brief.

## Global Constraints

- Preserve the root GPL-3.0-or-later licence, original copyright notices, Git history/tags, and fetch-only upstream relationship.
- Do not change Flutter application behaviour, UI, data schema, financial logic, Firebase configuration, branding, or infrastructure.
- Do not infer a licence where repository/package evidence is absent; emit `NOASSERTION` and an explicit review gap.
- Use committed lockfiles and reviewed manifests as the reproducible source of truth.
- Keep generated outputs byte-for-byte stable for unchanged inputs.

## Review Focus

1. A newly added Pub dependency must appear in both inventory and SPDX output and make `--check` fail until regenerated.
2. Git/path dependencies must preserve the locked revision/path and modification status instead of being represented as ordinary hosted packages.
3. Missing licence evidence must remain visible as `NOASSERTION`, never silently inherit a guessed licence.
4. iOS pods and Android direct dependencies must be represented without pretending Android transitive resolution is locked.
5. Release mode must reject placeholder source URLs, untagged/unmapped source, missing hashes, or absent GPL/provenance files.

---

### Task 1: Deterministic dependency and licence inventory library

**Files:**
- Create: `budget/tool/compliance/sbom_lib.dart`
- Create: `budget/test/compliance/sbom_lib_test.dart`

**Interfaces:**
- Produces: lock parsers, licence-text classifier, normalized component model, deterministic SPDX/inventory/report renderers.

- [ ] Write focused parser, classification, determinism, and missing-evidence tests.
- [ ] Run the tests and verify they fail because the library does not exist.
- [ ] Implement the minimal dependency-free library.
- [ ] Run focused and complete Flutter tests.
- [ ] Commit the tested library.

### Task 2: Source manifests, generator CLI, and canonical artifacts

**Files:**
- Create: `compliance/components/non_pub_components.json`
- Create: `compliance/provenance/cashew-upstream.json`
- Create: `budget/tool/compliance/generate_sbom.dart`
- Create: `compliance/inventory/current-components.json`
- Create: `compliance/reports/current-components.md`
- Create: `compliance/sbom/current.spdx.json`
- Test: `budget/test/compliance/sbom_generator_contract_test.dart`

**Interfaces:**
- Consumes: Task 1 renderers; committed Pub/CocoaPods locks; resolved package licence files.
- Produces: `generate_sbom.dart [--check] [--version <version>]` and canonical checked-in artifacts.

- [ ] Write contract tests for provenance, manual components, generated paths, and stale-output detection.
- [ ] Verify the tests fail before the manifests/CLI exist.
- [ ] Add reviewed component/provenance records and implement the generator.
- [ ] Generate current artifacts twice and prove byte stability.
- [ ] Run focused and complete tests.
- [ ] Commit the generator, manifests, and outputs.

### Task 3: Automated GPL/source release gate

**Files:**
- Create: `budget/tool/compliance/release_compliance.dart`
- Create: `compliance/release/release-manifest.template.json`
- Create: `budget/test/compliance/release_compliance_test.dart`

**Interfaces:**
- Consumes: canonical outputs and provenance from Task 2.
- Produces: audit mode and strict `--release-manifest` validation suitable for release automation.

- [ ] Write tests for missing licence/provenance, unresolved-evidence accounting, stale generation, placeholders, source tag/commit/archive hash, and Corresponding Source URL.
- [ ] Verify the tests fail because the checker does not exist.
- [ ] Implement the minimum release checker and template.
- [ ] Run focused tests, generator `--check`, audit-mode checks, and the complete suite.
- [ ] Commit the release gate.

### Task 4: Human audit and release procedure

**Files:**
- Create: `compliance/README.md`
- Create: `docs/transformation/18_OPEN_SOURCE_COMPLIANCE_SBOM.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: Tasks 1-3 results and audit gaps.
- Produces: repeatable operator instructions, ownership/provenance boundaries, and a release checklist.

- [ ] Document component coverage, licence evidence, unresolved native/asset/font gaps, and generation/check commands.
- [ ] Document Cashew/ÓLA ownership boundaries and release-time GPL obligations without claiming legal clearance.
- [ ] Link the compliance package from the repository README while preserving upstream history and notices.
- [ ] Run final generator/checker, SPDX structural validation, full Flutter suite, established analysis policy, and source-scope diff checks.
- [ ] Commit documentation and final generated artifacts.
