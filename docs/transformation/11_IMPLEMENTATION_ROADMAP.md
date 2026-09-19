# Implementation Roadmap

This roadmap preserves Cashew as the technical baseline and places irreversible identity, data, and cloud decisions before visual expansion. Each phase has an explicit exit gate. Work stops after this audit until approval is given.

## Phase 0 — Working Cashew baseline

**Purpose:** Turn the audited source into a reproducible, testable baseline without changing product behavior.

- Pin/document Flutter 3.19.6 and Dart 3.3.4 in developer/CI setup.
- Add the compatible missing `flutter_lints` development dependency and triage first-party diagnostics.
- Replace the stale counter test with startup and core transaction smoke tests.
- Add schema-v33–v46 migration fixtures, integrity checks, and financial invariants.
- Verify Android debug/release builds and physical/emulator behavior.
- Verify iOS builds and device/simulator behavior on macOS/Xcode.
- Record baseline screenshots and synthetic test data; test web in a normal browser.

**Exit gate:** Dependencies resolve from lockfile; agreed analysis baseline and tests are green; web, Android, and iOS build/run evidence exists; repository is tagged. No redesign.

### Phase 0C status — data-safety gates met

The forward-only v47 repair now makes supported v33/v36/v39/v41/v45/v46 fixtures converge on the canonical current schema while preserving the asserted financial data. Production restore validates and migrates a temporary copy, native activation has retained safety/rollback files, web activation has a previous-byte snapshot, and the full 43-test suite plus release web build/runtime smoke are green. See `13_DATA_SAFETY_REMEDIATION.md`.

The current verdict is **PASS — PHASE 0C DATA-SAFETY GATES MET; MOBILE RELEASE READINESS REMAINS UNVERIFIED**. Phase 1 planning may begin only after explicit approval. Keep these release gates visible:

1. Execute Android debug/release and device restore drills on a provisioned Android host.
2. Execute iOS simulator/device builds and restore drills on macOS/Xcode.
3. Measure existing dangling references and approve non-destructive cleanup/cascade semantics before enabling foreign keys.
4. Design and security-review an encrypted, checksummed, versioned backup envelope and recovery UX.
5. Add browser failure-injection coverage for IndexedDB/local-storage replacement and recovery.
6. Reduce strict analyzer debt incrementally without mixing it into infrastructure or identity changes.

Phase 1 must preserve the v47 data contract, migration fixtures, compatibility identifiers, and restore safety while separating infrastructure. It must not combine Firebase/account separation with rebranding or redesign.

## Phase 1 — Infrastructure separation

**Purpose:** Ensure development no longer depends on original Cashew-controlled identities.

- Approve legal entity, permanent package/bundle IDs, owned domains, and environment naming.
- Create development and staging Firebase/Google projects only.
- Introduce validated non-secret environment configuration.
- Register development OAuth clients, app links, capabilities, and test store products as needed.
- Version Firestore rules/indexes and add emulator security tests.
- Decide compatibility policy for Cashew backups and appDataFolder data.
- Establish secret management, CI access, signing custody, and incident ownership.

**Exit gate:** A new-identity development build can run without original production services; no production project/data is connected; security review approves the boundary.

### Phase 1 status — owner checkpoint reached

The codebase now defaults to local-only operation and contains no active upstream Firebase/OAuth/deep-link/store/support configuration. Environment validation, service gating, Firestore policy source, and old-infrastructure regression tests are implemented. Drift v47 and Phase 0C restore safety are unchanged.

Remaining exit work is owner/provisioning dependent: approve native IDs/domain, create owned development/staging Firebase and OAuth clients, run Firestore emulator tests, verify cloud flows using synthetic data, and complete native signing/device tests. Production stays disconnected. Phase 2 must not begin merely because the code is safely disconnected.

## Phase 2 — New brand foundation

**Purpose:** Establish a legally cleared, technically complete brand system before redesigning core screens.

- Finalize product name, trademark review, voice, terminology, accessibility target, and market/audience definition.
- Produce original logo/icon families, launch assets, color roles, typography licenses, and foundational design tokens.
- Replace development-build names, support/legal URLs, email identities, domains, and permission language through the brand manifest.
- Define GPL/source/attribution presentation and publish draft privacy/terms/support pages.
- Establish localization content guidance and rename product-facing terminology without changing stored data semantics.
- Build automated checks for old-brand strings/assets and environment-identity mismatches.

**Exit gate:** Brand/legal approval, complete token and asset package, development builds on all targets, no accidental original service use, and documented remaining Cashew legal attribution.

## Phase 3 — Design system

**Purpose:** Translate approved brand foundations into Figma and reusable Flutter primitives.

- Build Figma foundations and component/state library from `10_REBRAND_PLAN.md`.
- Implement mapped Flutter tokens and components with accessibility, localization, RTL, and responsive tests.
- Add a component gallery/sandbox and visual-regression strategy.
- Keep feature calculations and database behavior unchanged.

**Exit gate:** Figma/Flutter component parity and approved accessibility/visual regression baselines.

## Phase 4 — Core UI redesign

**Purpose:** Apply the design system to proven workflows in controlled slices.

- Redesign onboarding, shell/navigation, dashboard, transactions, transaction editor, budgets, accounts, analytics, recurring, search, and settings.
- Extract typed view models/services only where required by each screen.
- Run old/new behavioral parity, migration, and usability tests with synthetic data.

**Exit gate:** Core workflows retain financial results and data compatibility across mobile/web; usability and accessibility acceptance passes.

## Phase 5 — Existing feature customization

**Purpose:** Change product behavior only after the new shell is stable.

- Decide KEEP/MODIFY/REPLACE/REMOVE items from the feature map.
- Harden import/export, backup/restore, sync conflicts, notification ingestion, and privacy controls.
- Finalize monetization and support behavior.
- Ship changes behind migration-safe flags where appropriate.

**Exit gate:** Approved product scope, regression suite, privacy review, and migration/restore drills.

## Phase 6 — New financial modules

**Purpose:** Add lower-risk modules before architectural outliers.

- Extend goals and emergency-fund tracking first.
- Add forecasting and financial-health metrics after calculation-service extraction.
- Design assets, liabilities, debt, and credit utilization as one coherent domain expansion.
- Defer investments until instrument/lot/market-data architecture is approved.

**Exit gate:** Versioned schemas, migration fixtures, audited calculations, explainable metrics, and export/delete coverage.

## Phase 7 — Cloud and account architecture

**Purpose:** Build production-grade identity, household sharing, and reliable multi-device data.

- Decide local-first versus server-authoritative boundaries.
- Design users/households/roles, invitations, audit, conflict resolution, deletion, retention, and recovery.
- Replace client-trusted shared-budget operations with tested rules/server authority where needed.
- Add encrypted, validated, version-aware backup and recovery.

**Exit gate:** Threat model, penetration/security testing, disaster-recovery exercise, privacy/data-subject workflows, and production readiness review.

## Phase 8 — AI functionality

**Purpose:** Add an optional, constrained assistant after data/service boundaries are mature.

- Define allowed use cases and prohibited advice/actions.
- Use narrow audited financial tools rather than raw-database disclosure.
- Add consent, redaction, retention/deletion, evaluation, hallucination safeguards, rate/cost controls, and human confirmation for mutations.
- Complete financial-regulatory, privacy, and model/vendor review.

**Exit gate:** Safety/privacy evaluations, deterministic calculation parity, auditability, incident controls, and explicit user opt-in.

## Phase 9 — Security, privacy, and legal review

**Purpose:** Perform an independent release-focused assessment across the complete product.

- Mobile/web threat modeling, dependency/SBOM review, secret/signing audit, cloud rules/API testing, data-at-rest/backup review, and permission minimization.
- GPL compliance, third-party notices, source-distribution plan, store-term review, privacy/consumer/subscription/AI compliance.

**Exit gate:** Critical/high issues resolved, legal sign-off, release source bundle verified, and incident/data-deletion procedures exercised.

## Phase 10 — Testing and beta

**Purpose:** Validate reliability with representative users and devices.

- Automated unit/widget/integration/migration/visual/accessibility tests in CI.
- Device matrix, offline/concurrency/low-storage/timezone/currency/localization testing.
- Closed alpha/beta with telemetry limited by the approved privacy policy.
- Rehearse upgrade, rollback, backup restore, account deletion, and support escalation.

**Exit gate:** Release criteria and crash/data-integrity thresholds met; no unresolved migration or financial-calculation severity-one defects.

## Phase 11 — Android/iOS production release

**Purpose:** Publish controlled, supportable releases.

- Create signed reproducible builds and exact Corresponding Source archives/tags.
- Complete store listings, privacy labels/data safety, subscriptions, review credentials, support and status channels.
- Stage rollout with monitoring, rollback, and migration-support coverage.
- Release web/PWA only with equivalent source/license and security controls.

**Exit gate:** Store approval, staged rollout health, published source/attributions, support ownership, and post-release review.

## Inputs required before Phase 2 begins

Phase 1 should meet its exit gate first. The product owner should then provide:

1. Legal entity/publisher name, target countries, and legal counsel contact/decision on GPL distribution.
2. Trademark/domain/store clearance results for the official name **ÓLA HEDGE FINANCE**.
3. Owned domains and support/privacy/legal contact addresses.
4. Brand brief: audience, positioning, personality, accessibility commitment, and prohibited associations.
5. Terminology decisions and product scope priorities, including features to hide or retain.
6. Original logo/icon direction, licensed typography constraints, and any approved visual references.
7. Target platforms/device minimums and localization/RTL markets.
8. Monetization strategy and store-account ownership.
9. Approved development/staging identifiers and infrastructure owners from Phase 1.
10. Decision on Cashew-backup import compatibility and whether existing users/data must migrate.

## Stop gate

Phase 1 is authorized and has reached its owner decision/provisioning checkpoint. This roadmap does not authorize Phase 2, visual redesign, new features, AI, or schema work. Do not proceed until Phase 1 owned-infrastructure gates pass and the owner explicitly approves the next phase.
