# Phase 0C Data-Safety Remediation

Verification date: 2026-09-18

Branch: `phase-0c/data-safety-remediation`

Starting revision: `a14f60f891559cc7fc131730b033d1049c64117d`

## 1. Verdict

**PASS — PHASE 0C DATA-SAFETY GATES MET; MOBILE RELEASE READINESS REMAINS UNVERIFIED.**

All supported historical fixtures now converge on schema v47 without losing the tested financial data, the full 43-test suite is green, production restore validates and migrates a temporary copy before activation, failed native activation rolls back, and the release web build/runtime smoke passes. This is a suitable data-safety baseline for Phase 1 planning. It is not evidence that Android or iOS production builds work, and it is not production approval.

## 2. Scope and constraints

This phase addressed only the Phase 0B data-safety blockers:

- historical schema convergence;
- financial-data migration invariants;
- reference-integrity measurement;
- validate-first, recoverable backup restore;
- regression and release-web verification.

No Firebase project, package/bundle identity, branding, UI, AI feature, product feature, or production service was changed. Released v33–v46 schema snapshots and migration callbacks remain present. No migration was rewritten and no foreign-key enforcement was enabled.

## 3. Root-cause findings

The v33, v36, v39, and v41 failures were real direct-upgrade defects, not bad fixtures:

1. The v40→v41 callback used the current `budgets` definition instead of the versioned v41 definition. SQLite's double-quoted string compatibility caused absent column names such as `"income"` to become literals, which then violated the Boolean check. Because the error was caught, `all_category_fks` survived and later typed updates failed against the non-canonical table.
2. The v39→v40 callback constructed the current objectives table. Later callbacks then attempted to add columns already present and swallowed the duplicate-column errors.
3. Historical paths did not acquire the current `DEFAULT '0'` clauses for wallet references in transactions, budgets, and scanner templates.
4. `Constant(DateTime.now())` embedded a process-time integer in schema SQL, so a migrated schema could differ from a fresh schema depending on migration duration.

The old callbacks still print their caught errors when an old fixture runs. That log is historical behavior. The new v47 step is deliberately not broad-caught and makes the final physical schema canonical or fails the upgrade.

## 4. Forward-only schema-v47 repair

Schema v47 is the sole corrective migration. It rebuilds affected financial tables from their v47 Drift definitions after all older callbacks finish. Existing current columns are copied, obsolete physical columns are omitted, stable SQL `CURRENT_TIMESTAMP` defaults replace process-time literals, and the resulting schema is compared with the exported v47 snapshot.

The repair canonicalizes wallets, categories, objectives, budgets, transactions, category limits, associated titles, scanner templates, and delete logs. It does not reset amounts, dates, categories, accounts, recurrence, objectives, transfers, or tombstones. Legacy `beforeOpen` mutations that depended on process-global settings are skipped for upgrades reaching v47.

An old sentinel wallet value is resolved only when a backed-up selected-wallet setting identifies a real wallet or exactly one wallet exists. Ambiguous multi-wallet data fails migration instead of inventing an account assignment.

## 5. Immutable migration evidence

The committed Drift snapshots now cover v33 through v47. Data-bearing fixtures exercise v33, v36, v39, v41, v45, and v46, plus a fresh/current v47 database. Fixtures use only columns available in their source version and synthetic data only.

| Source | Result to v47 | Notable coverage |
|---|---|---|
| v33 | PASS | Identifier conversion, wallets/currencies, income/expense, budgets, recurrence, limits, templates, tombstones |
| v36 | PASS | Same core financial preservation after later legacy shape |
| v39 | PASS | Objective-table creation conflict is canonicalized |
| v41 | PASS | Objectives and category filtering converge |
| v45 | PASS | Multi-wallet/income budget era converges |
| v46 | PASS | Transfer pairs and current objective fields converge |
| Fresh v47 | PASS | Runtime schema matches the exported current schema |

## 6. Financial invariants protected

Migration tests assert more than row existence:

- exact primary keys and row counts;
- multiple wallets and currencies;
- exact decimal transaction values;
- income, expense, per-wallet, and aggregate sums;
- categories and supported subcategories;
- recurrence fields;
- budgets, category limits, and inclusion/exclusion relationships;
- objectives and transaction-objective links;
- reciprocal transfer pairs and same-currency neutrality;
- archived/type fields where available;
- delete-log tombstone preservation;
- target schema equality and SQLite integrity.

The tests do not claim coverage for arbitrary real-world corruptions. They establish reproducible representatives for every supported boundary selected in this phase.

## 7. Reference-integrity audit

`auditDatabaseReferences` is a read-only audit used by tests and restore validation. It reports source keys by relationship without logging financial rows. It checks:

- transaction wallet, category, subcategory, objective, loan objective, paired transaction, shared budget, and serialized excluded-budget references;
- category parent references;
- budget primary wallet and serialized wallet/category/excluded-category references;
- objective wallet references;
- category-limit wallet/category/budget references;
- scanner-template wallet/category references.

Malformed serialized JSON is an integrity violation. Restore also requires paired transfers to be reciprocal.

## 8. Foreign-key decision

**DO NOT ENABLE YET.**

SQLite enforcement remains off because historical databases may already contain orphans, several relationships are serialized JSON rather than declared constraints, and existing delete/update behavior has no reviewed cascade policy. Enabling enforcement without remediation could block legitimate app operations or tempt destructive cleanup.

The safe sequence is: measure real data, define per-relationship repair semantics, add non-destructive user-visible resolution where needed, test delete/update behavior, then introduce enforcement through a separately reviewed forward migration. Restore is stricter: a candidate containing unresolved required relationships is rejected before live data changes.

## 9. Native validate-first restore

Native restore now follows this order:

1. create a unique temporary working directory;
2. validate the SQLite header and minimum size;
3. open the candidate and read `user_version`;
4. reject unsupported versions, missing tables, failed integrity, or declared reference failures;
5. open the temporary file through `FinanceDatabase` so supported older backups migrate to v47;
6. close and re-inspect the migrated temporary file, including critical current columns, the full reference audit, and transfer reciprocity;
7. close the live Drift connection only after candidate validation succeeds;
8. retain `db.sqlite.pre-restore-<id>.sqlite` as a safety copy;
9. copy the validated database to a same-directory stage, rename live to rollback, and rename stage to live;
10. re-open the activated file at the raw SQLite boundary;
11. remove the transient rollback file only after the post-activation check passes;
12. clear sync state only after successful activation.

The two-rename native swap is not advertised as transactionally atomic. Recoverability comes from the rollback file plus the retained safety copy.

## 10. Web validate-first restore

Web restore performs schema-version and integrity inspection on a disposable copy, then opens a separate isolated `InMemoryWebStorage` database to run supported Drift migration and the full reference audit. Only migrated current-schema bytes are eligible for storage.

Before activation, the existing bytes are copied to `db_pre_restore_safety` in IndexedDB or `moor_db_str_db_pre_restore_safety` in local storage. The stored bytes are read back and revalidated. Store or post-check failure restores the prior bytes. Sync state changes only after success.

Browser storage replacement is not atomic across browser/process crashes. The previous-byte snapshot is the recovery mechanism. Automated interruption testing for IndexedDB requires a browser integration harness that is not available on this host; the web implementation is analyzer- and release-compile-checked.

## 11. Backup compatibility policy

| Candidate | Policy |
|---|---|
| Current v47 | Validate, stage, activate |
| Supported v33–v46 | Validate source, migrate only the temporary copy, revalidate, activate |
| Newer than v47 | Reject without downgrade or live mutation |
| Older than v33 | Reject; no frozen migration evidence supports it |
| Non-SQLite/truncated/corrupt | Reject before closing or changing live data |

The original live database is never used as the migration test surface. No down-migration exists.

## 12. Backup metadata design

Compatibility requires an eventual envelope around the raw SQLite payload with:

- format version;
- database schema version;
- application version/build;
- creation timestamp and source platform/device class;
- payload byte length;
- cryptographic checksum;
- compression and encryption algorithm identifiers;
- key-derivation/key-version metadata without secrets;
- optional compatibility capabilities.

Phase 0C keeps raw SQLite bytes for compatibility and defines restore format version `1` internally. It does not add the envelope, checksum, or encryption yet. Until that future format is approved, raw backup files remain sensitive, unencrypted financial data and must be protected accordingly.

## 13. Structured failures and privacy

Restore outcomes identify format, open, compatibility, schema, integrity, reference, migration, staging, activation, post-activation, or rollback failure. Native failure results can include safety/recovery paths and whether automatic rollback succeeded. Messages do not include transaction rows, backup bytes, account names, or amounts.

UI and Drive restore paths now await the structured restore operation. They no longer report a successful Drive restore from an asynchronous stream callback before validation has completed.

## 14. Restore failure matrix

The native contract suite contains 11 cases:

| Case | Expected safety property | Result |
|---|---|---|
| Valid current database | Activates after validation; safety copy retained | PASS |
| Supported older database | Temporary copy migrates to v47 before activation | PASS |
| Random bytes | Format rejection; live bytes unchanged | PASS |
| Truncated SQLite | Open rejection; live bytes unchanged | PASS |
| Deliberately corrupt SQLite | Integrity rejection; live bytes unchanged | PASS |
| Newer schema | Compatibility rejection; no downgrade | PASS |
| Too-old schema | Compatibility rejection | PASS |
| Missing required table | Schema rejection | PASS |
| Dangling relationship | Reference rejection | PASS |
| Temporary migration failure | Live bytes unchanged | PASS |
| Activation interruption | Previous live database automatically restored | PASS |

## 15. Test evidence

Fresh full-suite command:

```text
flutter test --no-pub --reporter compact
```

Result: **PASS — 43/43**.

The focused data-safety run contains 20 tests: seven migration/current-schema cases, two reference-audit cases, and eleven restore cases. Existing startup, CRUD, calculation, recurrence, brand, and widget tests remain in the full suite.

## 16. Analysis evidence

The agreed baseline command remains:

```text
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
```

It exits successfully with zero errors. Strict analysis remains nonzero because of pre-existing first-party lint debt. New data-safety files have focused analyzer coverage and add no warnings after import cleanup. Strict counts are recorded in `04_BUILD_STATUS.md` after final verification.

## 17. Build and runtime evidence

- `flutter pub get --enforce-lockfile --offline`: PASS; no dependency upgrade.
- Flutter 3.19.6 / Dart 3.3.4: retained.
- `flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --no-pub`: PASS.
- `flutter run -d web-server --release --no-pub`: PASS; HTTP 200 and `OLA Edge Finance` title found.
- Android: NOT RUN; Java, Android SDK, ADB, emulator, and device are absent.
- iOS: NOT RUN; the host is Windows and has no Xcode/CocoaPods.

The direct `flutter doctor -v` command was itself blocked by the workspace sandbox denying a broad home-directory listing. `flutter devices` found Windows and Chrome only, and explicit tool checks found no native mobile toolchain.

## 18. Files and dependency impact

Production changes are confined to database schema/migration code, reference audit, restore services/platform adapters, and the existing Drive restore await flow. Test schema helpers and fixtures were regenerated/expanded. `sqlite3 2.4.3` moved from development-only to direct application dependencies because the native restore validator uses its raw SQLite API; its locked version did not change.

Generated `tables.g.dart` changed substantially because the repository-pinned Drift generator was rerun. No Drift, SQLite, Flutter, Firebase, or application package was upgraded.

## 19. Remaining risks and mandatory follow-up

- Android and iOS builds, storage paths, lifecycle/restart behavior, low-storage handling, and device restore drills remain unverified.
- Web interruption recovery needs browser integration/failure-injection testing.
- Automatic foreign-key enforcement is intentionally deferred.
- Raw local databases and backups remain unencrypted.
- Historical callbacks still swallow errors before v47; v47 makes tested paths converge, but additional real-world fixture sampling is valuable.
- Backup safety-file retention/cleanup policy and a user-facing recovery workflow need product/security review.
- Restore currently validates structural/relationship invariants, not every possible domain/business invariant.
- Strict analyzer debt remains large.

These are not authorization to expand scope in Phase 0C.

## 20. Phase boundary

Phase 1 may be planned from this data-safe baseline, but infrastructure separation should remain isolated from product redesign. Before any mobile production release, complete Android/iOS build-and-device verification and restore drills, approve the foreign-key cleanup policy, specify encrypted/checksummed backup packaging, and conduct security/privacy review.

**STOP: no Firebase replacement, rebrand, redesign, or new feature work is authorized by this report.**
