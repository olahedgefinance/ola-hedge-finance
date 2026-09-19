# Phase 1 Infrastructure Separation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Disconnect ÓLA HEDGE FINANCE from original Cashew cloud/service identity while preserving the working local-first v47 application and creating safe, testable configuration boundaries.

**Architecture:** A typed `--dart-define` configuration object controls Firebase, Google account services, URLs, deep links, and store initialization. Development defaults to every external service off. Version-controlled Firestore rules and an automated upstream-identity guard make accidental reconnection detectable.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, Firebase Core/Auth/Firestore, Google Sign-In/APIs, Drift 2.18.0, SQLite/sqlite3, flutter_test, Firestore emulator rules tests.

**Spec:** `docs/superpowers/specs/2026-09-18-phase-1-infrastructure-separation-design.md`

## Global constraints

- Keep Drift schema v47 and all migrations untouched.
- No visual redesign, new finance feature, AI feature, production connection, broad refactor, or dependency upgrade.
- No secret values in source, docs, logs, tests, or commits.
- Use the exact official name `ÓLA HEDGE FINANCE` for current product identity.
- Preserve GPL notices and upstream attribution.
- Every production behavior change follows red-green TDD.

### Task 1: Freeze infrastructure and identity contracts

**Files:**
- Modify: `budget/test/brand/brand_identity_test.dart`
- Modify: `budget/test/brand/brand_manifest_contract_test.dart`
- Create: `budget/test/config/infrastructure_config_test.dart`
- Create: `budget/test/config/original_infrastructure_guard_test.dart`
- Create: `budget/lib/config/infrastructure_config.dart`
- Modify: `budget/lib/brand/brand_identity.dart`
- Modify: `budget/brand/brand_manifest.json`

- [ ] Write failing tests for official name, fail-closed development defaults, environment parsing, incomplete configuration, prohibited upstream identity, and Phase 1 production rejection.
- [ ] Add a repository scan that identifies forbidden upstream service values while allowing explicit legal/history/native-ID exceptions.
- [ ] Implement the smallest typed immutable configuration model and official identity changes.
- [ ] Run focused tests and commit.

### Task 2: Remove active upstream Firebase/OAuth configuration and gate cloud startup

**Files:**
- Modify: `budget/lib/main.dart`
- Modify: Firebase authentication/shared-budget helpers and Google-account entry points
- Delete: `budget/lib/firebase_options.dart`
- Delete: `budget/android/app/google-services.json`
- Delete: archived Google Services JSON variants
- Delete/replace: `budget/.firebaserc`
- Modify: `budget/android/app/build.gradle`
- Modify: `budget/web/index.html`
- Modify: `budget/ios/Runner/Info.plist`
- Modify: `budget/ios/Runner/Runner.entitlements`
- Modify: Android manifests

- [ ] Add failing tests around conditional Firebase configuration where practical.
- [ ] Make startup initialize Firebase only for a complete, explicitly enabled owned configuration.
- [ ] Make Firebase/Google entry points fail closed without configuration.
- [ ] Remove checked-in upstream project/client configuration and native/web app-link bindings.
- [ ] Run focused tests and compile/analyze touched paths.
- [ ] Commit.

### Task 3: Separate external endpoints, Drive identity, and store products

**Files:**
- Modify: support/privacy/donation/rating/store/Drive integration files
- Modify: platform display metadata and generated localization assets
- Modify: relevant tests

- [ ] Add failing tests proving upstream URLs, OAuth/store IDs, and Drive identity are absent from active defaults.
- [ ] Route external endpoints and account/store identifiers through typed optional configuration.
- [ ] Keep cloud and billing logic reusable but disabled until owned values exist.
- [ ] Replace current text identity with `ÓLA HEDGE FINANCE` without changing visual design.
- [ ] Run focused tests and commit.

### Task 4: Add Firestore policy source and verification harness

**Files:**
- Create: `budget/firestore.rules`
- Create: `budget/firestore.indexes.json`
- Modify: `budget/firebase.json`
- Create: `budget/firebase-tests/package.json`
- Create: `budget/firebase-tests/firestore.rules.test.mjs`
- Create: `budget/.firebaserc.example`

- [ ] Define owner/member rules matching the actual `budgets`, nested `transactions`, and `feedback` paths.
- [ ] Add emulator tests for unauthenticated access, owner access, invited-member access, unauthorized access, mutation boundaries, and feedback create-only behavior.
- [ ] Run the emulator suite when required local toolchains are present; otherwise record the exact environmental blocker.
- [ ] Commit.

### Task 5: Document the separation and owner checkpoint

**Files:**
- Create: `docs/transformation/14_INFRASTRUCTURE_SEPARATION.md`
- Modify: `docs/transformation/04_BUILD_STATUS.md`
- Modify: `docs/transformation/05_BRAND_SEPARATION.md`
- Modify: `docs/transformation/06_LICENSE_REVIEW.md`
- Modify: `docs/transformation/07_FIREBASE_MIGRATION.md`
- Modify: `docs/transformation/11_IMPLEMENTATION_ROADMAP.md`

- [ ] Record every old/new/removed/deferred identity and why.
- [ ] Document environment/config/secret handling, backup migration, Firestore rules, store/deep-link/platform work, GPL obligations, and owner inputs.
- [ ] Record all code/config changes and risks without secrets.
- [ ] Commit.

### Task 6: Verify and stop at the owner checkpoint

- [ ] Run the full Flutter test suite; require at least the existing 43 tests plus new Phase 1 coverage.
- [ ] Run Flutter analysis and classify any non-zero result without hiding diagnostics.
- [ ] Build release web and verify generated output contains no upstream cloud configuration.
- [ ] Run the upstream-infrastructure guard separately.
- [ ] Inspect the full diff for database changes, secrets, unrelated changes, licensing, and exact product naming.
- [ ] Produce the exact 15-answer final report and one readiness verdict.
- [ ] Stop without connecting production infrastructure, merging, or pushing.

