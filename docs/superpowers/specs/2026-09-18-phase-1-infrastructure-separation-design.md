# Phase 1 Infrastructure Separation Design

## Status and authority

This design implements the approved Phase 1 prompt on branch `phase-1/infrastructure-separation`, starting from Phase 0C commit `eeaf6f37259821e4400759c0fdce35cc8893ffbd`. The product name is **ÓLA HEDGE FINANCE**. This phase separates infrastructure and configuration; it does not authorize a visual redesign, feature work, AI, database-schema changes, or production deployment.

## Baseline and invariants

- Preserve Drift schema version 47, its immutable historical snapshots, migrations, and Phase 0C restore protections.
- Preserve existing financial features and local-first behavior.
- Do not connect an owned production Firebase, OAuth, store, domain, or messaging environment in this phase.
- Never commit credentials or private configuration.
- Keep GPL-3.0 notices and upstream attribution intact.
- Default builds must be safe and useful without cloud credentials: Firebase, Google account features, and store billing remain disabled until explicitly configured.

## Infrastructure inventory

The original runtime contains active references to the upstream Firebase project, Google OAuth clients, Firebase Hosting sites, the `cashewapp.web.app` app-link domain, upstream store identifiers, donation/support endpoints, and a Drive folder named `Cashew`. Firebase is used for Authentication and Firestore shared budgets/feedback; Google APIs support Drive backup/attachments and Gmail scanning. There is no Firebase Storage, Analytics, Crashlytics, Cloud Messaging, or Dynamic Links dependency. Notifications are local; Android also exposes notification-listener functionality.

Original configuration is spread across Dart, Android Google Services JSON, iOS URL schemes/entitlements, the web shell, `.firebaserc`, `firebase.json`, store constants, URLs, and display metadata. Package and bundle identifiers are platform identity, not secrets, but changing them has irreversible signing/store implications and therefore needs owner approval.

## Selected separation model

Introduce one typed compile-time configuration boundary. Environment is selected with `--dart-define`, with three named lanes: `development`, `staging`, and `production`. Development is the default. Cloud, Google-account, and store capabilities are independent opt-ins and fail closed when incomplete, when they reference known upstream infrastructure, or when production is selected during Phase 1.

The repository ships no live Firebase/OAuth configuration. Public Firebase client values are not server secrets, but they identify a live backend and must still be supplied outside version control through an owned configuration process. Private service-account keys, signing keys, refresh tokens, and store credentials must never enter the application repository.

Candidate identifiers, pending owner/domain/store approval:

- Android/iOS base: `com.olahedge.finance`
- Development: `com.olahedge.finance.dev`
- Staging: `com.olahedge.finance.staging`
- Firebase: `ola-hedge-finance-dev`, `ola-hedge-finance-staging`, and eventually `ola-hedge-finance-prod`

These are proposals, not implemented identities. The current package and bundle identifiers remain temporarily only where native project continuity requires them. A guard will prevent other upstream cloud/service identifiers from returning.

## Runtime behavior

App startup initializes Firebase only when an owned, complete configuration is explicitly enabled. Firebase-dependent screens must report the capability as unavailable rather than touching the upstream project. Google Drive, Gmail, and Google Sign-In follow the same gate. In-app purchases do not initialize until owned product identifiers and store records are supplied. Local database, backup-file import/export, analytics, budgets, accounts, transactions, and all offline features remain available.

Runtime support/privacy/donation URLs and email addresses become configuration, with no upstream default. The legal upstream source link remains because it supports GPL provenance. App-link parsing logic remains, while the old host association is removed until an owned domain and Digital Asset Links/Apple association files exist.

## Firebase and Firestore boundary

Version-control `firestore.rules`, `firestore.indexes.json`, emulator configuration, and rule tests. Rules require authentication, owner/member isolation for shared budgets, and create-only feedback. Membership is based on normalized authenticated email because the existing data model stores member emails; this remains a documented architectural limitation. No new production project is connected.

The repository retains Firestore data-access logic but must not reach any project by default. Emulator tests are required when Java/Firebase CLI are available; inability to run them is a release blocker, not grounds to weaken rules.

## Google data and backup compatibility

Drive `appDataFolder` is OAuth-client scoped in practice and the existing backup path belongs to upstream credentials. New OAuth configuration will not automatically expose old cloud backups. Preserve compatibility by retaining the Phase 0C local-file importer for schema v33-v47 and document a user-controlled export from the old app followed by local import into ÓLA HEDGE FINANCE. Do not reuse upstream OAuth or silently copy cloud data.

The visible Drive attachment folder becomes configurable and has no upstream default. Gmail scanning stays disabled until the owner creates a consent-screen, verifies scopes, and completes privacy/legal review.

## Store and platform capabilities

Remove upstream product identifiers and app-store record IDs from runtime defaults. Retain purchase logic behind configuration, but note that the current entitlement implementation lacks server-side receipt validation and is not production-ready. Remove the obsolete upstream deep-link domain, web OAuth metadata, and iOS OAuth URL scheme. Retain local notifications, notification-listener, biometric, quick-action, widget, camera/photo, and file capabilities for later per-platform privacy review; remove no functioning capability in this phase unless it is solely tied to upstream infrastructure.

## Automated guard

Add repository tests that scan active runtime/configuration locations for known upstream Firebase project IDs, hosts, OAuth client fragments, store IDs, donation/support identity, and Drive folder defaults. The guard permits legacy identifiers only in explicit legal/history documentation and the temporarily retained native package/bundle locations. Tests also enforce the official display name and reject the superseded working names.

## Owner checkpoint and completion

Phase 1 can make the code safe and disconnected, but it cannot declare owned infrastructure ready without owner-controlled inputs: legal entity/publisher identity, owned domain and email, approved final application IDs, Firebase projects, OAuth consent details, store accounts/products, privacy/support URLs, signing teams/keys, and data-retention/security decisions. The final verdict must distinguish a safely separated codebase from a configured production environment.

