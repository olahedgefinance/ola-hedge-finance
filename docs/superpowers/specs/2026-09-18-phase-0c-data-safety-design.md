# Phase 0C Financial Data Safety Design

## Status and authority

This design implements the approved Phase 0C prompt. It starts from Phase 0B commit `a14f60f891559cc7fc131730b033d1049c64117d` on branch `phase-0c/data-safety-remediation`. It does not authorize infrastructure, Firebase, brand, UI, AI, or product-feature work.

## Evidence

Independent runs reproduce failures from v33, v36, v39, and v41. The fixtures use schema-correct synthetic rows; the failures are not caused by invalid financial values.

- v33/v36/v39: v40→v41 calls `TableMigration(budgets)` using the current table instead of the versioned v41 shape. SQLite treats absent double-quoted column names such as `"income"` as string literals, violating the Boolean check. The caught error leaves `all_category_fks` in place. Later typed budget updates fail because they omit that still-required column.
- v33/v36/v39: v39→v40 creates `$ObjectivesTable(database)`, the current objectives shape, instead of the v40 shape. Later column additions report duplicates and are swallowed. Data is not shown lost in the fixture, but the path is structurally non-canonical.
- v33/v36/v39/v41: `wallet_fk` on transactions, budgets, and scanner templates never gains the v45 `DEFAULT '0'` clause because v44→v45 adds wallet data to only selected tables and does not rebuild these existing columns.
- v33: `Constant(DateTime.now())` is evaluated while table definitions are constructed, embedding a process-time Unix value into schema SQL. A long migration therefore differs from a freshly constructed target schema. This is a real non-deterministic schema definition, not a meaningful financial-data difference.

Real users updating directly across these versions can encounter the same migration implementation. The errors are swallowed, so the app may open at the latest `user_version` with a non-canonical physical schema.

## Chosen approach

Introduce schema v47 as a forward-only repair. Preserve every v33-v46 snapshot and callback. The new v46→v47 step rebuilds affected tables against the canonical v47 definitions after all older steps have run, copying all current columns and dropping only obsolete physical columns. Date defaults become Drift's stable SQL `currentDateAndTime` expression rather than a process-time literal.

The step must fail the upgrade if canonicalization fails. It must not wrap repair operations in broad `try/catch`, fabricate financial values, or delete rows. Historical post-open updates that depended on current application globals are skipped for upgrades that reach v47; v47 performs structural repair without changing valid wallet/category/objective assignments.

Alternatives rejected:

1. Rewriting old callbacks or snapshots would change shipped history and make compatibility evidence unverifiable.
2. Ignoring extra columns/default differences in the verifier would hide real non-canonical databases.
3. Accepting v46 as-is and repairing only restore would leave ordinary app upgrades unsafe.

## Historical fixtures and invariants

The migration harness will retain immutable synthetic schema snapshots and add data-rich fixtures at v33, v36, v39, v41, v45, and v46. Each fixture uses only columns available at that version and covers, where supported, multiple wallets/currencies, income, expenses, transfers, categories/subcategories, budgets, recurrence, objectives, paired transfers, archives, and tombstones.

Before and after migration, hand-derived summaries verify:

- row counts for financial/domain tables;
- transaction primary keys, types, amounts, recurrence fields, and relationships;
- per-wallet and total income/expense sums;
- transfer-pair neutrality;
- budget amount, inclusion relationships, and totals;
- objective links and contribution totals;
- identifier conversion from integers to strings;
- decimal values without rounding;
- delete-log/tombstone preservation;
- schema version, SQLite integrity, and declared reference integrity.

## Reference audit and foreign keys

Create a reusable read-only reference audit covering declared and serialized relationships: transaction wallet/category/subcategory/objective/pair links, category parent links, budget wallet and serialized wallet/category lists, category-limit links, scanner-template wallet/category links, and objective wallet links.

Phase 0C decision: **DO NOT ENABLE YET**. Current tables have no explicit cascade policy, historic databases may contain orphans, several relationships are serialized lists rather than SQLite foreign keys, and deleting a financial row to satisfy a constraint would be unsafe. Restore rejects a candidate with unresolved required-reference violations, but ordinary databases are only audited and reported. Enforcement requires a separately approved cleanup policy and delete/update semantics.

## Validate-first restore architecture

Restore becomes a data-layer operation with a structured result. UI and Google Drive entry points provide bytes but do not write storage directly.

Native flow:

1. Write candidate bytes into a unique temporary directory.
2. Verify SQLite header/openability, supported `user_version` (33 through 47), required tables, `integrity_check`, and references.
3. Open the temporary copy with `FinanceDatabase`, allowing supported older copies to migrate to v47.
4. Close and re-validate the migrated temporary copy, including financial/reference checks.
5. Copy the current live database to a retained safety file.
6. Copy the validated candidate into a same-directory staging file.
7. Close the live Drift connection, rename the live file to a rollback file, then rename staging to the live name.
8. Reopen at the raw SQLite boundary for post-activation verification.
9. On any activation/post-check failure, restore the rollback file and report failure.
10. Clear sync state only after successful activation. A restart remains required.

Renames on a single native filesystem reduce exposure but the two-name swap is not claimed to be transactionally atomic. The rollback and retained safety copy provide recoverability.

Web flow:

1. Validate and migrate candidate bytes in an isolated `InMemoryWebStorage` database.
2. Snapshot the current IndexedDB/local-storage bytes.
3. Store the validated migrated bytes.
4. On store/post-check failure, restore the snapshot.

IndexedDB replacement is not claimed to be atomic across browser/process crashes. The previous byte snapshot is the recovery mechanism. Web behavior is documented and compiled; browser failure simulation is limited by the available Windows host.

## Compatibility and metadata

- Same version: validate, stage, activate.
- Older supported v33-v46: validate, migrate temporary copy, revalidate, activate.
- Newer than v47: reject without touching live data.
- Older than v33: reject as unsupported because Phase 0C has no frozen schema evidence for it.
- Never downgrade.

Backups remain raw SQLite for backward compatibility. Phase 0C does not introduce an archive/encryption format. The validator returns format version `1`, schema version, byte length, creation/inspection time, and a checksum extension point; future encrypted/enveloped backups can add application version, timestamp, platform identifier, checksum, and encryption metadata without exposing financial rows. Raw backups remain unencrypted and must be treated as sensitive.

## Error handling

Validation failures are typed by stage and never close or mutate the live database. Activation failures attempt rollback before returning. If rollback itself fails, both the safety copy and rollback path are retained and surfaced in the result for manual recovery. Production logs/errors must not print financial rows or backup bytes.

## Exit verification

Phase 0C requires all supported migrations and restore failure cases to pass, no analyzer errors under the agreed baseline, a successful release web build and web-server smoke, explicit Android/iOS environment status, documentation updates, and no unrelated identity/infrastructure/product changes.
