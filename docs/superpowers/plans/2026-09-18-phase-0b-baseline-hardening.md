# Phase 0B Baseline Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a reproducible, tested Cashew baseline that protects the financial and migration behavior retained for the future product.

**Architecture:** Keep the Flutter monolith and Drift schema unchanged. Add native in-memory integration tests around the existing `FinanceDatabase`, generate Drift's official historical schema test helpers from the committed schema JSON files, and define an analyzer baseline that distinguishes generated/bundled code from first-party debt. Platform verification remains evidence-driven and environmental blockers are documented rather than bypassed.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, Drift 2.18.0, sqlite3, flutter_test, flutter_lints 3.0.2.

**Spec:** User-approved “ÓLA HEDGE FINANCE — PHASE 0B: BASELINE HARDENING” prompt in the originating task.

## Global Constraints

- Do not change schema version 46, historical migrations, Firebase, package/bundle IDs, OAuth clients, domains, IAP identifiers, or financial behavior.
- Do not upgrade the existing application dependency graph.
- Preserve the repository's already-established OLA Edge Finance display identity; do not extend or reverse branding in this phase.
- Prefer real in-memory SQLite and real Drift queries over mocks.
- Keep backup/restore behavior unchanged if validation reveals a data-loss risk; document the risk for a separately approved fix.

---

### Task 1: Meaningful analyzer baseline

**Files:**
- Modify: `budget/analysis_options.yaml`
- Create: `docs/transformation/12_BASELINE_HARDENING.md`

**Interfaces:**
- Consumes: `package:flutter_lints/flutter.yaml` restored in Phase 0.
- Produces: first-party analyzer scope excluding checked-in generated Drift code and bundled third-party packages.

- [ ] Add analyzer exclusions for `lib/database/tables.g.dart`, `lib/database/schema_versions.dart`, `test/generated/**`, and `packages/**`.
- [ ] Run strict `flutter analyze --no-pub` and capture error/warning/info counts.
- [ ] Run `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings`; require exit zero only when there are no analyzer errors.
- [ ] Classify retained diagnostics in the hardening report instead of mass-editing style debt.
- [ ] Commit the scoped analyzer configuration with the test foundation that relies on generated helpers.

### Task 2: Local startup and financial database tests

**Files:**
- Create: `budget/test/support/finance_database_fixture.dart`
- Create: `budget/test/core/application_startup_test.dart`
- Create: `budget/test/database/finance_database_crud_test.dart`
- Create: `budget/test/database/financial_invariants_test.dart`

**Interfaces:**
- Consumes: `FinanceDatabase`, generated Drift data classes, and `NativeDatabase.memory()`.
- Produces: `createTestDatabase()`, literal wallet/category/transaction/budget/objective fixtures, and real SQLite integration coverage.

- [ ] Build a test-only in-memory database fixture and deterministic entity factories.
- [ ] Verify a new local database opens at schema version 46, creates the ten expected tables, and passes `PRAGMA integrity_check`.
- [ ] Exercise transaction create, edit, delete, wallet/category assignment, and stored decimal round trips through real Drift methods.
- [ ] Verify a paired same-currency transfer sums to zero total wealth while preserving both account relationships.
- [ ] Verify budget totals include eligible paid expenses and exclude explicitly excluded transactions.
- [ ] Verify objective totals preserve linked transaction amounts.
- [ ] Verify invalid account/category relationships are reported by `PRAGMA foreign_key_check`, documenting actual foreign-key enforcement state.
- [ ] Run each target test file and the full suite.
- [ ] Commit the core financial smoke tests.

### Task 3: Historical migration harness

**Files:**
- Generate: `budget/test/generated/migrations/schema.dart`
- Generate: `budget/test/generated/migrations/schema_v33.dart` through `schema_v46.dart`
- Create: `budget/test/database/migration_test.dart`

**Interfaces:**
- Consumes: `budget/drift_schemas/drift_schema_v33.json` through `drift_schema_v46.json`, `SchemaVerifier`, and the unmodified `FinanceDatabase.migration` strategy.
- Produces: representative v33, v36, v39, v41, v45, and v46 compatibility verification.

- [ ] Generate minimal schema helper classes with `dart run drift_dev schema generate drift_schemas test/generated/migrations`.
- [ ] Insert hand-authored wallet, category, transaction, and budget rows into each representative historical schema.
- [ ] Migrate v33, v36, v39, v41, and v45 fixtures to v46 with the real migration strategy and validate the runtime schema against the exported v46 schema.
- [ ] Assert identifier conversion, row counts, amounts, relationships, newly introduced nullable columns, `user_version`, `integrity_check`, and `foreign_key_check` after migration.
- [ ] Open an exported v46 schema without migration and verify the current-schema contract.
- [ ] Run the migration test independently and with the full suite.
- [ ] Commit generated verification support and migration tests without modifying historical schema JSON or production migration code.

### Task 4: Recurrence and backup/restore safety characterization

**Files:**
- Create: `budget/test/struct/recurrence_invariants_test.dart`
- Create: `budget/test/database/backup_restore_contract_test.dart`

**Interfaces:**
- Consumes: `countTransactionOccurrences`, `updatePredictableKey`, SQLite backup files, and current schema version 46.
- Produces: deterministic recurrence-key/occurrence tests and executable backup compatibility checks.

- [ ] Verify predictable recurrence keys advance deterministically and do not fork duplicate identifiers.
- [ ] Verify daily, weekly, monthly, and yearly occurrence counts using literal date fixtures, including the 999-occurrence guard.
- [ ] Verify a valid current-schema SQLite backup passes version, integrity, and relationship checks in a test-only preflight harness.
- [ ] Verify corrupt SQLite bytes and schema versions newer than 46 are rejected by the test preflight.
- [ ] Document that production `overwriteDefaultDB` currently writes before equivalent validation and therefore remains a data-loss risk requiring a separately approved behavioral fix.
- [ ] Run recurrence/backup tests and the full suite.
- [ ] Commit the safety characterization tests.

### Task 5: Web and platform verification

**Files:**
- Modify: `docs/transformation/04_BUILD_STATUS.md`
- Modify: `docs/transformation/11_IMPLEMENTATION_ROADMAP.md`
- Modify: `docs/transformation/12_BASELINE_HARDENING.md`

**Interfaces:**
- Consumes: exact local Flutter 3.19.6 toolchain and committed lockfile.
- Produces: reproducible verification commands and platform classifications.

- [ ] Run offline locked dependency resolution.
- [ ] Run scoped baseline analysis, strict analysis inventory, and all tests.
- [ ] Build release web with CanvasKit and no icon tree shaking.
- [ ] Start `flutter run -d web-server --release --no-pub`, verify HTTP 200, and stop the process cleanly.
- [ ] Record browser smoke-test status separately from compilation/server status.
- [ ] Record Android as environmentally unverified if JDK/SDK/ADB remain unavailable, with exact later commands and integration checklist.
- [ ] Record iOS as environmentally unverified on Windows, with exact Xcode/signing/service checklist.
- [ ] Confirm protected schema, migration, Firebase, identity, and branding files are unchanged.

### Task 6: Acceptance documentation and clean handoff

**Files:**
- Modify: `docs/transformation/04_BUILD_STATUS.md`
- Modify: `docs/transformation/11_IMPLEMENTATION_ROADMAP.md`
- Complete: `docs/transformation/12_BASELINE_HARDENING.md`

**Interfaces:**
- Consumes: fresh verification evidence from Tasks 1–5.
- Produces: PASS / CONDITIONAL PASS / FAIL baseline decision with explicit risks.

- [ ] Record starting revision `0fae418f1760441e64bd9559eedd16b0cf1b629b` and branch `phase-0b/baseline-hardening`.
- [ ] Enumerate every tracked change, test behavior, migration version, analyzer class, and platform result.
- [ ] Mark backup preflight absence, analyzer warnings/style debt, thin UI coverage, Android tooling, and iOS host availability as explicit remaining risks.
- [ ] Run `git diff --check`, full tests, analyzer baseline, protected-path diff, and secret-pattern scan.
- [ ] Commit documentation, require a clean worktree, and do not push or merge.
