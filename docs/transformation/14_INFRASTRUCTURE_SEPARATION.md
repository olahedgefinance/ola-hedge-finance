# Phase 1 Infrastructure Separation

Verification date: 2026-09-18

Branch: `phase-1/infrastructure-separation`

Starting revision: `eeaf6f37259821e4400759c0fdce35cc8893ffbd`

Official product identity: **ÓLA HEDGE FINANCE**

## 1. Current verdict

The development codebase is disconnected from Cashew-controlled production services by default. It starts as a local-first application without Firebase, Google account services, Drive/Gmail, store billing, deep links, or upstream support endpoints. Original Firebase/OAuth client files are removed from the working tree, and an automated test prevents known infrastructure identity from returning to active source/configuration.

Phase 1 is not fully complete because no owner-controlled development Firebase/Google project exists, Firestore emulator tests cannot run on this host, and permanent native IDs/domain/store identities have not received owner approval. No production environment is connected.

## 2. Safe Git start

- Phase 0C was fully committed at `eeaf6f37259821e4400759c0fdce35cc8893ffbd`.
- The dedicated branch is `phase-1/infrastructure-separation`.
- Initial Git status was clean.
- Initial full suite: PASS, 43/43.
- Initial release web build: PASS on Flutter 3.19.6 / Dart 3.3.4.
- No history was rewritten and nothing was pushed or merged.

## 3. Identity and infrastructure manifest

`REPLACE NOW` means completed on this branch unless a note says otherwise. Public identifiers are recorded where necessary; client keys and full OAuth client IDs are deliberately not repeated.

| Identity/service | Actual source/configuration | Classification | Phase 1 disposition |
|---|---|---|---|
| Product display name | Typed brand identity, manifest, Android/iOS/web metadata, localization | REPLACE NOW | Set to **ÓLA HEDGE FINANCE**; visual identity deferred |
| Dart package/internal project | `budget` in `pubspec.yaml`, imports, iOS bundle name | KEEP TEMPORARILY | Internal rename would be a broad refactor and is not product-facing |
| Android application ID | `com.budget.tracker_app` and source namespace | KEEP TEMPORARILY | Candidate replacement documented; owner/store approval required |
| iOS bundle ID | `com.budget.tracker-app`; test IDs use `com.budget...` | KEEP TEMPORARILY | Candidate replacement documented; Apple registration required |
| Apple development team | Existing team identifier in Xcode project | REPLACE LATER | Replace with owner-controlled team during native setup |
| Web/PWA identity | Manifest/title/social metadata | REPLACE NOW | Product text updated; upstream absolute asset URLs removed |
| Web hosting domain | Original Firebase Hosting references | REMOVE | Removed; no replacement domain invented |
| Firebase project/apps | Original project plus generated Dart/web/Android configuration | REMOVE | Active binding and `.firebaserc` removed; owned projects required |
| Google OAuth clients | Android JSON, iOS generated value/scheme, web meta tag | REMOVE | Removed; new consent screen/platform clients required |
| Google Sign-In | Account/backup code and scopes | KEEP TEMPORARILY | Retained behind `OLA_GOOGLE_ACCOUNT_ENABLED`; default off |
| Firebase Auth | Google credential sharing auth; anonymous feedback auth | KEEP TEMPORARILY | Retained behind validated configuration; default off |
| Firestore shared budgets | `budgets`, nested `transactions`, owner/member fields | KEEP TEMPORARILY | Logic retained; version-controlled rules/indexes/harness added |
| Firestore feedback | Anonymous-authenticated create | KEEP TEMPORARILY | Rules allow authenticated create only |
| Storage/Analytics/Crashlytics | No package or use found | REMOVE / NOT PRESENT | Do not add without a product decision |
| Messaging/push | No package or push implementation | REMOVE / NOT PRESENT | Obsolete iOS push entitlement removed; local notifications remain |
| Dynamic Links | No Firebase package found | REMOVE / NOT PRESENT | Generic app-link parser remains reusable |
| Android/iOS app links | Upstream host in manifest/entitlements | REMOVE | Bindings removed until an owned domain exists |
| iOS OAuth URL scheme | Original reverse-client scheme | REMOVE | Removed; regenerate from owned OAuth later |
| Drive backup/sync | Drive `appDataFolder` and Google auth | KEEP TEMPORARILY | Logic retained but unreachable by default; Phase 0C safety unchanged |
| Drive attachment folder | Literal upstream product folder | REPLACE NOW | Required configuration; no default identity |
| Gmail scanning | Readonly + modify scopes | KEEP TEMPORARILY | Retained but disabled; scope/privacy verification required |
| IAP product IDs/App Store ID | Original product/listing identifiers | REMOVE | Removed; configuration required before billing starts |
| Entitlement logic | Client `purchaseID`; no backend validation | REVIEW | Reusable prototype, not production-grade entitlement security |
| Donation/support/privacy/email | Original developer/hosted properties | REMOVE | Optional configuration with no upstream default |
| Upstream GitHub link | About/legal source context | LEGAL ATTRIBUTION — RETAIN | Preserved for provenance/source obligations |
| Root GPL/copyright | `LICENSE` | LEGAL ATTRIBUTION — RETAIN | Unchanged |
| Historical changelog/backup text | History/compatibility context | LEGAL ATTRIBUTION — RETAIN / REVIEW | Not used as the new product identity |
| Third-party credits | Flutter, Drift, chart, API, icon/asset credits | LEGAL ATTRIBUTION — RETAIN | Rights audit remains a release gate |
| Currency-rate endpoint | jsDelivr/Fawaz Ahmed data | KEEP TEMPORARILY | Not Cashew-controlled; needs operational/privacy review |
| Google Sheets import template | Original public template | REPLACE LATER | Create an owned template before production |
| Local notifications | Scheduled local notifications | KEEP TEMPORARILY | No Firebase dependency |
| Notification listener | Android service/parser | KEEP TEMPORARILY | Sensitive platform capability; privacy review required |
| Widgets/quick actions | Android widgets and Flutter quick actions | KEEP TEMPORARILY | Logic stays; identity/assets change later |
| Biometrics/camera/photo/files | Local platform plugins/permissions | KEEP TEMPORARILY | Logic stays; permission/privacy review required |
| Signing material | Ignored Android key files; Apple team in project | REPLACE LATER | Use owner-controlled secrets/signing |

## 4. Proposed permanent identifiers — OWNER DECISION REQUIRED

- Android production: `com.olahedge.finance`
- Android development: `com.olahedge.finance.dev`
- Android staging: `com.olahedge.finance.staging`
- iOS production: `com.olahedge.finance`
- iOS development: `com.olahedge.finance.dev`
- iOS staging: `com.olahedge.finance.staging`
- Firebase candidates: `ola-hedge-finance-dev`, `ola-hedge-finance-staging`, and eventually `ola-hedge-finance-prod`, subject to availability

These are proposed, not implemented. Approval requires an owned domain/publisher identity, store-record availability, Google/Apple account ownership, signing strategy, and a decision on whether existing app installs/data must upgrade in place. Changing native IDs creates a new installed/store identity.

## 5. Environment and secret model

`InfrastructureConfig` selects `development`, `staging`, or `production` using `--dart-define`. Development is the default. Production is deliberately rejected in Phase 1. Firebase, Google-account, and store capabilities are independent opt-ins and default to false.

Configuration groups are `OLA_ENVIRONMENT`, Firebase public client fields, Google platform clients/Drive folder, store products/listing ID, and support/privacy/donation/app-link values. Enabled-but-incomplete or known-upstream configuration fails validation. Default startup does not initialize Firebase; normal lifecycle work skips Google/Drive/Gmail/Firestore and billing.

`.gitignore` excludes `.firebaserc`, Google Services JSON, `GoogleService-Info.plist`, generated Firebase options, `.env` variants, Dart-define JSON, signing files, and rules-test dependencies. `.firebaserc.example` contains placeholders only.

Public Firebase client values select a backend and still require controlled provisioning. Service accounts, OAuth client secrets, refresh tokens, signing keys/passwords, store API keys, production exports, and future AI keys belong only in managed secret storage/CI.

## 6. Firebase service map

| Dependency | Actual purpose | New owned requirement | Risk/gate |
|---|---|---|---|
| Core | Application bootstrap | App registration per platform/environment | Wrong project can cross tenant boundaries |
| Auth | Google sharing auth; anonymous feedback | Providers, linking/deletion policy | Anonymous abuse controls required |
| Firestore | Shared budgets/transactions and feedback | Rules, indexes, retention, quotas, monitoring | Emulator tests before real data |
| Google Sign-In | Firebase/Drive/Gmail identity | Consent screen and platform clients | Gmail scopes may require verification |
| Storage | Not used | None | Do not enable |
| Analytics | Not used | None | Consent decision before addition |
| Crashlytics | Not used | None | Privacy decision before addition |
| Messaging | Not used | None | No push setup now |
| Dynamic Links | Not used | None | Owned app-link domain later if required |

### CODEX can do

- Maintain fail-closed configuration/tests and wire owner-supplied public client data.
- Maintain rules/indexes and run local/emulator/build verification on a provisioned host.

### OWNER must do

- Create/own Google Cloud/Firebase projects, billing, IAM, audit retention, alerts, and break-glass access.
- Register platform apps after IDs are approved.
- Create OAuth consent branding, verified domain, support/privacy pages, origins/redirects, iOS scheme, and Android SHA-1/SHA-256 fingerprints.
- Decide anonymous Auth/feedback, quotas, retention/deletion, and supply public client configuration through a controlled channel.

## 7. OAuth checklist

Android requires an owned package ID and SHA-1/SHA-256 for each dev/staging certificate. iOS requires an owned bundle ID, client, reverse-client scheme, Apple team/capabilities, and matching Firebase app. Web requires an owned web client, authorized HTTPS origins/redirects, verified domain, and consent links.

Drive requests profile/email and `drive.appdata`; attachments add `drive.file`. Gmail requests readonly and modify (used to mark messages read). Consent-screen verification, revocation/deletion behavior, cancellation/expiry/offline tests, and a sensitive-scope privacy review are mandatory.

## 8. Drive backup and compatibility decision

Drive `appDataFolder` is scoped to the authorizing application context; an owned ÓLA client should not be assumed to see Cashew files. Reusing upstream OAuth would violate separation.

- A, continuously discover Cashew app-data: unsafe/unreliable and coupled.
- B, only accept new-product backups: strands compatible users.
- C, provide a one-time user-controlled migration: safest balance.

**Recommendation: C.** Export from Cashew, then import the local file into ÓLA HEDGE FINANCE. Phase 0C accepts supported v33-v47 candidates, migrates a temporary copy, revalidates, and preserves rollback/safety data. Do not weaken it or silently access upstream storage. A future backup envelope should add product/schema/app version, timestamp, checksum, encryption/key metadata, and legacy-origin metadata.

## 9. Firestore security

The repository previously contained no rules or indexes. Phase 1 adds rules, empty explicit indexes, emulator configuration, and synthetic tests.

Policy: deny unmatched paths; authenticate budgets/feedback; allow owner or email-listed member reads; allow members non-access content and nested transaction changes; prevent members changing owner/owner-email/membership or deleting; allow owners access changes/deletion; allow authenticated feedback create only.

The email-membership/client-sync model still lacks a complete invitation, ownership-transfer, revocation, account-deletion, payload/rate-limit, and server-authority design. Tests cover owner/member/stranger/anonymous and access escalation, but are **NOT RUN** because Java, Firebase CLI, and Node dependencies are absent. Do not enable an owned project before they pass.

## 10. Deep links, purchases, and platform capabilities

The generic add-transaction parser remains, but Android intent filters, iOS associated domain, and OAuth scheme were removed. Restore them only with an owned HTTPS domain, Android Digital Asset Links, Apple association file, and approved package/team/bundle IDs.

Old monthly/yearly/lifetime IDs, App Store review ID, and product-specific Play URLs are removed. Billing requires configured owned products. The existing local `purchaseID` entitlement has no server receipt validation, ledger, webhooks, refund/fraud handling, or account binding and is not production secure.

Local notifications remain; no push package exists and the unused iOS push entitlement was removed. Notification-listener parsing, widgets, quick actions, biometrics, camera/photo/files, and background behavior remain as app logic and require native privacy/permission/identity testing.

## 11. GPL/client-service boundary

The Flutter client remains GPL-3.0-or-later. Branding, commercial sale, store distribution, package IDs, and owned cloud projects do not make it proprietary. Preserve the root licence, upstream copyright/provenance, modification/no-warranty notices, and exact Corresponding Source for every distributed binary.

An independently implemented network service may have separate licensing, but this is fact-specific. Moving covered code server-side or tightly integrating proprietary client modules is not an automatic workaround.

Release checklist: legal/store-term review; immutable source tag per binary; complete Corresponding Source/build scripts without secrets; in-product GPL/upstream/modification/source/no-warranty notices; SBOM and asset/font/dependency audit; no incompatible added restrictions; reviewed contracts/boundary for future backend/AI.

## 12. Owner decision checkpoint

1. Approve/reject Android `com.olahedge.finance` and dev/staging variants.
2. Approve/reject the matching iOS IDs and provide an owned Apple team.
3. Create/approve development and staging Firebase names; keep production disconnected.
4. Provide web/app-link/OAuth/source/support/privacy/legal domain decisions.
5. Create OAuth consent/platform clients and supply public configuration/signing fingerprints safely.
6. Provide legal publisher/entity, store publisher, support email, privacy contact, and legal contact.
7. Approve the one-time user-controlled Cashew export/import recommendation.
8. Obtain professional GPL/client-server review.
9. Provide owned Apple/Google developer accounts and entitlement strategy.
10. Configure IAM/billing/audit/alerts, DNS/association files, signing, legal pages, store records, and CI secret storage.

## 13. Changes made

- Added typed fail-closed environment configuration and explicit Firebase bootstrap.
- Removed upstream Firebase Dart/web/Android files and archived Android variants.
- Made Android Google Services conditional on an ignored owner-supplied file.
- Gated Auth, Google Sign-In, Drive/Gmail lifecycle, Firestore sharing, and billing.
- Removed upstream app-link/associated-domain/OAuth scheme and unused push entitlement.
- Updated product-facing text identity without changing visual assets/layout.
- Made support/privacy/donation/store/Drive identity optional configuration.
- Added Firestore rules/indexes/emulator tests and placeholder project mapping.
- Added old-infrastructure/source identity regression tests.
- Did not change Drift v47, migrations, finance logic, dependencies, or Phase 0C restore.

## 14. Verification evidence

| Gate | Result |
|---|---|
| Initial baseline | PASS — 43/43 |
| Focused Phase 1 configuration/guard | PASS — 9/9 |
| Final full Flutter suite | PASS — 52/52 |
| Agreed analyzer baseline | PASS — zero errors |
| Strict analysis | Nonzero: 5,253 historical findings, zero errors |
| Release web build | PASS after separation |
| Generated web configuration scan | No upstream API keys, Firebase domains/buckets, OAuth clients, app IDs, or support email |
| Firestore emulator | NOT RUN — toolchain/dependencies absent |
| Android/iOS | NOT RUN — toolchains absent |

## 15. Remaining risks and exit gate

- No owned development Firebase/Google configuration exists; cloud behavior is disabled, not integration-proven.
- Rules are unexecuted and email membership is weaker than server-authoritative roles.
- Native IDs/domain/signing/OAuth/support/legal/store decisions remain open.
- Drive/Gmail, sharing, links, purchases, notifications, widgets, permissions, and restore need device tests.
- Client-only entitlements are insecure for production; raw backups remain unencrypted.
- Strict analyzer debt and asset/font/licence review remain.
- Currency API and Google Sheets template need ownership/availability/privacy decisions.

The code is safely disconnected and ready to receive owned development configuration, but the exit gate requiring owned configuration and tested rules is not met.

**INFRASTRUCTURE SEPARATION NOT READY**
