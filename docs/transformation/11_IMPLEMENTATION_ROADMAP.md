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

### Phase 0B status — blocked on data safety

The reproducible toolchain, release web build, first-party no-error analyzer baseline, and 26 non-migration tests are now established. Phase 0 is not complete: four historical migration fixtures fail, production restore is not validate-first/atomic, foreign-key enforcement is disabled, and Android/iOS remain unverified.

Complete these remediation gates before Phase 1:

1. Approve a forward-only migration repair design (expected as a new schema version, not edits to historical shipped migrations).
2. Freeze representative data-bearing upgrade fixtures and require every supported historical version to converge on the current schema without financial-data loss.
3. Add backup preflight, supported-version checks, integrity/foreign-key validation, an atomic replacement strategy, and failure recovery.
4. Audit existing dangling references, define cleanup semantics, and decide when foreign-key enforcement can safely be enabled.
5. Return the complete test suite to green and repeat release web verification.
6. Complete the Android and iOS checklists in `12_BASELINE_HARDENING.md` on provisioned hosts.

Infrastructure separation must not begin merely because the web artifact builds; the database and restore gates protect user financial history.

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

Phase 1 should be approved and substantially complete first. The product owner should then provide:

1. Legal entity/publisher name, target countries, and legal counsel contact/decision on GPL distribution.
2. Final or shortlist product names with trademark/domain/store availability results.
3. Owned domains and support/privacy/legal contact addresses.
4. Brand brief: audience, positioning, personality, accessibility commitment, and prohibited associations.
5. Terminology decisions and product scope priorities, including features to hide or retain.
6. Original logo/icon direction, licensed typography constraints, and any approved visual references.
7. Target platforms/device minimums and localization/RTL markets.
8. Monetization strategy and store-account ownership.
9. Approved development/staging identifiers and infrastructure owners from Phase 1.
10. Decision on Cashew-backup import compatibility and whether existing users/data must migrate.

## Stop gate

This audit does not authorize Phase 1 or Phase 2 implementation. No infrastructure replacement, rebranding, redesign, feature change, or new schema work should begin until explicitly approved.
