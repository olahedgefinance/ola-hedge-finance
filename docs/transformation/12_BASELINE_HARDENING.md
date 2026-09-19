# Phase 0B Baseline Hardening

Verification date: 2026-09-18

Branch: `phase-0b/baseline-hardening`

Starting revision: `0fae418f1760441e64bd9559eedd16b0cf1b629b`

## Starting State

The earlier Phase 0 work established Flutter 3.19.6/Dart 3.3.4 as the reproducible toolchain, restored the configured Flutter lint package, replaced the generated counter test, and proved that a release web artifact could be built and served. It did not yet exercise the financial model, database migrations, backup safety, or native mobile builds.

The repository already contained the approved display identity `OLA Edge Finance`. Phase 0B preserved that state and did not extend, revert, or otherwise undertake branding work. The future name supplied for a later phase, `ÓLA HEDGE FINANCE`, is intentionally not applied here; its spelling and accent should be confirmed before the brand phase.

## Changes Made

Phase 0B made only test, analysis-scope, and narrowly justified correctness changes:

- Added an in-memory Drift/SQLite fixture and deterministic entity builders for application database tests.
- Added startup, CRUD, financial-invariant, recurrence, backup-contract, and historical-migration tests.
- Generated test-only Drift schema helpers from the repository's committed v33-v46 schema snapshots.
- Declared the already-resolved `sqlite3 2.4.3` package as a direct development dependency for the Windows test harness. No application dependency was upgraded.
- Excluded generated Drift verifier code, the generated database file, and locally bundled third-party packages from first-party analyzer accounting.
- Corrected one application defect in `getTotalTowardsObjective`: goal objectives were filtered using the loan foreign key and therefore returned zero. The correction uses `objectiveFk`; its regression test was observed failing before the fix and passing afterward.

No Firebase configuration, platform identifier, database schema, schema version, migration callback, branding asset, or production service was changed.

## Static Analysis

The agreed first-party baseline command is:

```text
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
```

It exits successfully because there are no analyzer errors. Strict `flutter analyze --no-pub` remains nonzero with 5,255 pre-existing findings: 0 errors, 132 warnings, and 5,123 informational findings. Generated and bundled third-party sources are excluded; the remaining debt is first-party code and should be reduced incrementally, not by an unrelated repository-wide rewrite.

The warning inventory is dominated by protected/visible `notifyListeners` members, unused imports/locals, null-aware dead code, and missing `mustCallSuper` calls. These need behavior-aware cleanup rather than mechanical suppression. New Phase 0B test/support files pass focused analysis.

## Tests

The prior suite contained eight tests. Phase 0B adds 18 non-migration tests, for 26 passing tests when historical migration cases are excluded:

- application startup and current-schema integrity;
- transaction create, edit, delete, assignment, exact stored amount, and sync tombstone behavior;
- transfer-pair relationships and same-currency net-zero wealth effect;
- budget eligibility rules;
- objective contribution totals;
- recurrence key stability and daily, weekly, monthly, yearly, and guard-limit behavior;
- test-only backup preflight for valid, corrupt, and newer-version SQLite files.

The complete suite also contains six migration tests. The fresh full-suite result is 28 passed and 4 failed: two migration tests pass and four intentionally expose historical incompatibilities. The passing subset must not be described as a green repository baseline while those migration failures remain.

## Database Migration Coverage

The harness constructs actual historical databases from the committed Drift schema snapshots and asks the production migration strategy to upgrade them to schema v46. It then checks the resulting schema and integrity.

Verified results:

| Case | Result | Finding |
|---|---|---|
| Fresh/current v46 schema | PASS | Runtime schema matches the exported current schema |
| v45 to v46 | PASS | Most recent migration reaches the expected current schema |
| v33 to v46 | FAIL | Historical/current schema mismatch |
| v36 to v46 | FAIL | Historical/current schema mismatch |
| v39 to v46 | FAIL | Migration callbacks conflict with historical table shape |
| v41 to v46 | FAIL | Migration callbacks conflict with historical constraints/shape |

Observed incompatibilities include:

- obsolete `budgets.all_category_fks` surviving some paths;
- expected default clauses absent on `transactions.wallet_fk`, `budgets.wallet_fk`, and `scanner_templates.wallet_fk`;
- the v40-to-v41 budget table migration violating its income check constraint for some historical rows;
- the v39-to-v40 path creating a later `objectives` shape, after which subsequent callbacks try to add duplicate columns;
- time-dependent `DateTime.now()` defaults producing non-stable schema comparisons;
- current data-class updates in `beforeOpen` assuming columns unavailable in some historical shapes.

These are production data-safety issues, not test flakiness. Historical migrations were not rewritten because doing so can change the upgrade behavior of already-shipped databases. The recommended repair is a separately reviewed, forward-only schema version (for example v47) with fixed historical fixtures, explicit data transformations, idempotence checks, and backup/rollback drills.

## Financial Invariants

The tests now protect these current behaviors:

- finite transaction amounts are stored without unintended rounding;
- non-finite amounts are rejected;
- editing a transaction updates the row rather than duplicating it;
- deleting a transaction creates the expected sync tombstone;
- selected subcategories are normalized consistently;
- a linked transfer pair is reciprocal and has a net-zero same-currency wealth effect;
- paid, eligible expenses affect a budget while unpaid or excluded transactions do not;
- goal contributions use the goal foreign key and loan contributions use the loan foreign key;
- recurrence expansion is stable and bounded.

SQLite foreign-key enforcement is currently disabled (`PRAGMA foreign_keys = 0`). Invalid references can therefore be inserted, after which `PRAGMA foreign_key_check` reports them. Phase 0B records that behavior rather than silently enabling enforcement, because enforcement may reject existing data or alter production workflows. A future decision needs data-quality measurement and a migration/remediation plan.

## Web

`flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --no-pub` completed successfully and produced a release bundle. `flutter run -d web-server --release --no-pub` compiled and served the application; an HTTP request returned status 200 and the generated page contained the expected `OLA Edge Finance` title.

`flutter run -d chrome --release --no-pub` compiled the application, but the host Chrome process failed after repeated GPU-process crashes in its sandbox. This is classified as an environmental browser-launch failure because the release build and HTTP web-server smoke test both succeeded. Interactive browser behavior still needs testing in a normal desktop environment.

## Android

Android was not buildable on the verification host: no Android SDK, JDK, Android Studio, emulator, `adb`, or physical Android device was available. This is an environment gap, not evidence that the Android project builds.

Required verification on a provisioned host:

1. Install a JDK compatible with the checked-in Gradle 7.5/Android Gradle Plugin 7.3.1 combination, Android SDK platform 34, platform tools, build tools, and an emulator image.
2. Run `flutter doctor -v`, accept required SDK licences, and confirm `flutter devices` lists the test target.
3. Run dependency resolution from the lockfile and execute analysis plus the full test suite.
4. Run `flutter build apk --debug --no-pub`, install/run it on an emulator and a representative device, and capture startup/navigation evidence.
5. Configure non-production signing before attempting a release app bundle; do not reuse original production credentials.
6. Exercise notifications, background work, quick actions, home-screen widgets, biometrics, deep links, Google sign-in, file import/export, and test-store purchase flows with non-production service configuration.

## iOS

iOS cannot be compiled on this Windows host. Required verification on macOS:

1. Install the repository-compatible Flutter SDK, Xcode and command-line tools, CocoaPods, and a compatible Ruby environment if required.
2. Resolve pods without upgrading application dependencies and run `flutter doctor -v`.
3. Build and run `flutter build ios --simulator --no-pub` on a supported simulator.
4. Open the generated workspace in Xcode and verify a device build using development-only signing and an owned test bundle identity.
5. Validate URL schemes/associated domains, notifications, background modes, biometrics, widgets, Google sign-in, import/export, and test-store purchases.
6. Verify entitlements, privacy usage descriptions, deployment target, archive/export, and release signing only after infrastructure separation.

## Known Issues

- Four historical migration paths fail the schema-compatibility harness.
- The production restore flow replaces the live database before validating that the candidate is a valid, supported Cashew database. The test-only preflight demonstrates the checks that are needed, but production behavior was not changed in this phase.
- Database replacement is not an atomic validate-then-swap operation and therefore poses a data-loss risk if interrupted or given an invalid file.
- Foreign-key enforcement is disabled, permitting dangling references.
- Strict analysis remains red because of substantial first-party warning/information debt.
- Android and iOS builds are unverified due to absent platform toolchains.
- Interactive Chrome launch is unverified due to a host GPU/sandbox crash.
- Current cloud/authentication/in-app-purchase flows were not exercised against original or new production services.

## Baseline Acceptance

**FAIL — BASELINE NOT READY.**

The application has a reproducible Flutter/Dart toolchain, a successful release web build, a meaningful 26-test non-migration safety net, and a corrected objective-total defect. It is not yet an acceptable data-safe baseline because the full test suite is red on four historical upgrade paths, restore validation is unsafe, foreign-key policy is unresolved, and native mobile builds remain unverified.

Before infrastructure separation or brand implementation begins:

1. design and test a forward-only migration repair without rewriting shipped history;
2. freeze representative, data-bearing fixtures for supported historical versions;
3. implement validate-first, version-aware, atomic backup restore with recovery tests;
4. decide and stage the foreign-key remediation/enforcement policy;
5. make the complete migration/test suite green;
6. complete Android and iOS build/run verification on provisioned hosts.

No Phase 1 or Phase 2 work is authorized by this report.

## Phase 0C superseding status — 2026-09-18

The Phase 0B failures above remain the historical evidence that triggered remediation; they are no longer the current branch result.

Phase 0C introduced a forward-only v47 canonicalization rather than editing v33–v46 history. Data-rich v33, v36, v39, v41, v45, and v46 fixtures now all reach a schema identical to fresh v47 while preserving the tested row identities, exact amounts, wallet/currency totals, recurrence, budgets, objectives, paired transfers, and tombstones. The fixture logs still expose swallowed errors in historical callbacks, after which the fail-closed v47 repair canonicalizes the tested database.

Production restore is now validate-first:

- native candidates are inspected, migrated, and revalidated in temporary storage before the live connection closes; activation retains a safety copy and rolls back after interruption/post-check failure;
- web candidates are inspected and migrated in isolated memory; existing bytes are snapshotted and restored after store/post-check failure;
- unsupported newer/too-old versions, random/truncated/corrupt databases, missing schema, dangling references, and temporary migration failures are rejected;
- sync state is cleared only after activation succeeds.

Foreign-key enforcement remains intentionally disabled. A new read-only audit covers declared and serialized financial relationships, restore rejects an unsafe candidate, and ordinary data is not silently deleted or reassigned. Enabling constraints requires a separately approved cleanup and cascade policy.

Fresh Phase 0C verification:

| Gate | Result |
|---|---|
| Full tests | PASS — 43/43 |
| Supported schema cases | PASS — 7/7 |
| Restore contract cases | PASS — 11/11 |
| Reference-audit cases | PASS — 2/2 |
| Agreed no-error analyzer baseline | PASS |
| Strict analysis | FAIL — 0 errors, 132 warnings, 5,121 infos; historical debt |
| Release web build | PASS |
| Web-server HTTP/title smoke | PASS |
| Android | NOT RUN — toolchain/device absent |
| iOS | NOT RUN — Windows host |

The superseding verdict is **PASS — PHASE 0C DATA-SAFETY GATES MET; MOBILE RELEASE READINESS REMAINS UNVERIFIED**. Detailed design, failure matrix, recovery guarantees, and remaining risks are in `13_DATA_SAFETY_REMEDIATION.md`. This verdict permits Phase 1 planning only when explicitly approved; it does not authorize infrastructure changes, rebranding, redesign, or feature work.
