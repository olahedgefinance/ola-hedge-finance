# Phase 0C Data Safety Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make supported historical upgrades and backup restore preserve financial data and fail safely before the existing baseline advances.

**Architecture:** Add a forward-only v47 canonicalization migration and data-rich migration fixtures. Route device and Drive restores through platform-specific validate-first services that migrate only temporary copies and preserve a recoverable live-database safety copy until activation passes.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, Drift 2.18.0, SQLite/sqlite3 2.4.3, Drift web storage, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-18-phase-0c-data-safety-design.md`

## Global Constraints

- Preserve v33-v46 migration snapshots and released callbacks.
- Never silently discard rows, reset financial values, fabricate financial data, or downgrade a database.
- Do not enable foreign keys, redesign UI, rebrand, migrate Firebase, or add product features.
- Use synthetic data only.
- Every production behavior change follows red-green TDD.

---

### Task 1: Freeze root-cause evidence and data-rich migration fixtures

**Files:**
- Modify: `budget/test/database/migration_test.dart`
- Modify: `budget/test/support/finance_database_fixture.dart`

**Interfaces:**
- Produces: representative v33/v36/v39/v41/v45/v46 fixtures and literal pre/post financial summaries.

- [ ] Expand the fixture builder using only version-available columns.
- [ ] Add assertions for row counts, identifiers, exact amounts, income/expense totals, wallet balances, recurrence, budgets, objectives, pairs, and tombstones.
- [ ] Run each failing source independently and record the expected red failures.
- [ ] Commit the characterization tests.

### Task 2: Add the forward-only v47 canonical migration

**Files:**
- Modify: `budget/lib/database/tables.dart`
- Regenerate: `budget/lib/database/tables.g.dart`
- Regenerate: `budget/lib/database/schema_versions.dart`
- Create: `budget/drift_schemas/drift_schema_v47.json`
- Create/regenerate: `budget/test/generated/migrations/schema_v47.dart`
- Modify: `budget/test/database/migration_test.dart`
- Modify: `budget/test/brand/brand_manifest_contract_test.dart`

**Interfaces:**
- Produces: schema version 47 and a v46→v47 repair that canonicalizes physical tables without changing financial rows.

- [ ] Point migration expectations at v47 and observe failures.
- [ ] Replace process-time schema defaults with stable SQL current-time expressions.
- [ ] Generate v47 schema artifacts.
- [ ] Add `from46To47` table canonicalization with no swallowed exceptions.
- [ ] Skip legacy global-dependent post-open mutation when the v47 repair handled the upgrade.
- [ ] Run every migration fixture and verify schema plus financial convergence.
- [ ] Commit the migration repair.

### Task 3: Add reusable reference auditing and decide enforcement

**Files:**
- Create: `budget/lib/database/reference_audit.dart`
- Create: `budget/test/database/reference_audit_test.dart`

**Interfaces:**
- Produces: `Future<DatabaseReferenceAudit> auditDatabaseReferences(GeneratedDatabase db)` with per-relationship violations and a safe summary.

- [ ] Write failing tests for wallet, category, subcategory, objective, paired-transaction, budget, category-limit, scanner-template, and serialized-list violations.
- [ ] Implement read-only auditing; never delete or rewrite rows.
- [ ] Verify valid historical/current fixtures report no violations and malformed fixtures are classified.
- [ ] Commit the reference audit.

### Task 4: Implement native validate-first recoverable restore

**Files:**
- Create: `budget/lib/database/backup/restore_models.dart`
- Create: `budget/lib/database/backup/native_restore.dart`
- Modify: `budget/lib/database/platform/native.dart`
- Replace/modify: `budget/test/database/backup_restore_contract_test.dart`

**Interfaces:**
- Produces: a structured inspection/result API and a native restore function accepting candidate bytes, live file, safety location, and lifecycle callbacks.

- [ ] Write failing tests proving truncated, random, corrupt, newer, too-old, missing-table, integrity/reference-invalid, and migration-failing candidates leave live bytes unchanged.
- [ ] Implement preflight and temporary-copy migration.
- [ ] Write failing tests for activation interruption and rollback.
- [ ] Implement same-filesystem staging, safety copy, activation verification, and rollback.
- [ ] Prove valid same-version and supported older backups activate while retaining a safety copy.
- [ ] Commit native restore safety.

### Task 5: Route web and UI restore entry points through validation

**Files:**
- Modify: `budget/lib/database/platform/web.dart`
- Modify: `budget/lib/database/platform/unsupported.dart`
- Modify: `budget/lib/widgets/importDB.dart`
- Modify: `budget/lib/widgets/accountAndBackup.dart`
- Add tests where executable without a browser.

**Interfaces:**
- Consumes: structured restore result and candidate validator.
- Produces: validate-before-store web behavior and UI/Drive error propagation.

- [ ] Add isolated in-memory web validation/migration and previous-byte rollback.
- [ ] Make both local-file and Drive restore await a successful structured result before declaring success or changing settings.
- [ ] Analyze/compile web code and commit the integration.

### Task 6: Complete verification and documentation

**Files:**
- Create: `docs/transformation/13_DATA_SAFETY_REMEDIATION.md`
- Modify: `docs/transformation/04_BUILD_STATUS.md`
- Modify: `docs/transformation/08_DATABASE_ARCHITECTURE.md`
- Modify: `docs/transformation/11_IMPLEMENTATION_ROADMAP.md`
- Modify: `docs/transformation/12_BASELINE_HARDENING.md`

**Interfaces:**
- Produces: auditable failure matrix, platform guarantees, test/build evidence, remaining risks, and one baseline verdict.

- [ ] Run locked offline dependency resolution, full tests, focused tests, and agreed/full analysis.
- [ ] Build release web and repeat web-server HTTP smoke.
- [ ] Re-check Android/iOS toolchain status without installing massive SDKs.
- [ ] Audit branch diff for schema history, identifiers, infrastructure, branding, secrets, and unrelated changes.
- [ ] Write the required 20-section report and update baseline gates.
- [ ] Commit documentation and stop without merge/push.
