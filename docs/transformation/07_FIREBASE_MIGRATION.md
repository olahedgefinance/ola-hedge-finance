# Firebase and External-Service Migration

No new production infrastructure should be connected during the audit or visual rebrand. This checklist separates the application from the original Cashew services while preserving a reproducible local baseline.

## Current service inventory

| Service | Current purpose | Code/configuration surfaces | New-product requirement |
|---|---|---|---|
| Firebase Core | Platform app initialization | `lib/firebase_options.dart`, Google-services files, iOS plist/project, web bootstrap | New dev/staging/prod Firebase apps |
| Firebase Auth | Google sign-in; anonymous authentication for selected cloud operations | Auth helpers, Google Sign-In setup, OAuth clients/schemes | New OAuth clients, consent screen, identity policy |
| Cloud Firestore | Shared budgets and transaction subcollections | Shared-budget/database helpers | New schema/rules/indexes, emulator tests, ownership model |
| Firebase Hosting | Web deployment and app/deep-link domain | `.firebaserc`, `firebase.json`, web metadata, platform links | Owned hosting target/domain and association files |
| Google Drive | Raw database backup, device sync, and optional attachment upload | Drive helpers, Google scopes, backup/sync settings | New OAuth project, backup compatibility/retention design |
| Gmail | Optional transaction extraction using scanner templates | Gmail helpers, scanner templates, sign-in scopes | Separate explicit consent; scope and privacy review |
| Local notifications | Upcoming/overdue/recurring and reminder notifications | Notification helpers and platform manifests | Rebrand channels/text; test scheduling/timezones |
| Android notification listener | Optional extraction from other-app notifications | Android service and notification templates | Explicit opt-in, disclosure, data minimization |
| In-app purchases | Cashew premium subscriptions/lifetime product | IAP code and product constants | New store products, entitlements, restore/server-validation plan |
| Currency-rate API | Latest exchange rates | HTTP/currency helpers | Reliability, attribution, caching, terms, fallback review |
| Google Sheets | Public-sheet CSV import | Import URL conversion/download | Validation and privacy review |
| App stores/review | Rating and listing links | Platform/store helper constants | New application listings |

Firebase Analytics, Firebase Crashlytics, Sentry/PostHog-style telemetry, and Firebase Cloud Messaging were not found in the dependency/configuration path inspected. Do not infer that production observability exists. Notifications are local/scheduled rather than FCM push.

## Original-infrastructure ownership

The checked-in configuration identifies the original Cashew Firebase project, web hosts, package/bundle registrations, OAuth clients, and app links. Those identifiers must be treated as belonging to the original application. Client-side Firebase identifiers are not generally server secrets, but they still identify the wrong environment and are intentionally not copied into this document.

Configuration surfaces include:

- `budget/lib/firebase_options.dart`;
- `budget/android/app/google-services.json` and historical/dev variants;
- the iOS Firebase/URL-scheme project configuration;
- `budget/.firebaserc` and `budget/firebase.json`;
- inline web Firebase and Google sign-in configuration in `budget/web/index.html`;
- Android/iOS app/deep-link declarations;
- IAP product IDs and external service URLs in source.

No Firestore rules or indexes were found in the repository. They must be obtained from an authorized original deployment or, preferably, redesigned and verified against the new threat model. Absence from this checkout must not be mistaken for permissive or known-safe behavior.

## Data and authentication model found

There is no local `User` table. Most finance data is device-local. Firebase identity is introduced for cloud operations. Shared budgets use Firestore documents plus transaction subcollections and store identity/membership fields such as user IDs and email addresses. The app performs create/update/delete synchronization from client code.

This model needs adversarial rules testing. Email-based membership, ownership transfer, invitation/revocation, deleted accounts, offline writes, and malicious client payloads need explicit semantics before a new backend is enabled.

Drive sync uploads database files per client and merges rows using modification timestamps and delete tombstones. It is separate from Firestore shared budgets. Restoring or reauthorizing under a new OAuth client may make historical Cashew app-data files inaccessible because Drive's appDataFolder is application-scoped.

## Migration checklist

### 1. Ownership and environments

- Establish the publishing legal entity and controlled Google/Apple accounts.
- Reserve permanent Android package ID, iOS bundle ID, web domain, and redirect/app-link domains.
- Create separate development, staging, and production Firebase/Google Cloud projects.
- Define accountable owners, least-privilege roles, billing alerts, break-glass access, and audit-log retention.

### 2. Configuration boundary

- Introduce environment selection without committing service-account keys or signing secrets.
- Generate platform client configuration independently for each environment.
- Validate at startup that package/bundle/domain and Firebase project match the selected environment.
- Remove historical configuration files only after confirming they are unused and preserving repository history/legal records.
- Add secret scanning and CI checks; never place service-account credentials in the Flutter client.

### 3. Authentication

- Configure a new OAuth consent screen, brand verification, support contacts, and privacy/terms URLs.
- Register Android signing fingerprints, iOS URL schemes, and approved web origins/redirects.
- Decide whether anonymous authentication is still required and define account linking/deletion behavior.
- Test sign-in cancellation, revoked grants, multiple accounts, token expiry, offline mode, and account deletion.

### 4. Firestore sharing

- Specify collections, field types, membership roles, ownership, invitations, revocation, deletion, and retention.
- Write rules and indexes as version-controlled infrastructure.
- Test rules with the Firebase emulator against cross-tenant reads/writes, forged email/UID fields, role escalation, and oversized payloads.
- Add server-authoritative operations where client-only enforcement is insufficient.
- Define schema versioning and migration for shared data before accepting production writes.

### 5. Drive backup and sync

- Decide whether the new app can or should import user-exported Cashew backups.
- Add backup metadata, checksum, schema version, app version, creation time, and optional encryption envelope.
- Validate into a temporary database before replacing the live database.
- Test interrupted upload/download, concurrent devices, clock skew, deletion conflicts, quota exhaustion, and revoked access.
- Publish retention, deletion, and recovery expectations.

### 6. Gmail and notification ingestion

- Treat Gmail read/modify and Android notification-listener access as separate optional features.
- Request the minimum scopes and explain why modification permission is needed to mark messages read.
- Keep parsed content local unless the user separately consents to cloud processing.
- Add redaction, template provenance, false-positive recovery, and deletion controls.
- Complete Google sensitive/restricted-scope verification if applicable.

### 7. Purchases, links, and release services

- Create new store products and entitlement identifiers; do not reuse Cashew products.
- Define server receipt validation and fraud/reconciliation behavior if premium access has material value.
- Host Android asset links and Apple association files on the owned domain.
- Rebuild local notification channel IDs/names and confirm migration behavior for existing installations.
- Add privacy-respecting crash reporting/monitoring only after policy and consent decisions.

## Secrets policy

Only public client configuration should enter the repository, and even that should be environment-specific and reviewed. Service-account JSON, private API keys, Android keystores/passwords, Apple signing material, store API keys, OAuth client secrets, and production database exports belong in managed secret stores. Documentation, test fixtures, logs, screenshots, commits, and AI prompts must not contain them.

## Go-live gates

Cloud features remain disabled for production until configuration isolation, authentication flows, Firestore rules tests, backup restore drills, account/data deletion, privacy disclosures, monitoring, incident response, and legal/security review pass in staging.

## Phase 1 implementation status — 2026-09-18

Completed in source:

- Removed original generated Dart Firebase options, Android Google Services variants, active `.firebaserc`, web OAuth/Firebase bootstrap, iOS OAuth scheme, and app-link bindings.
- Added a typed `--dart-define` boundary. Development defaults to all service capabilities off; production is rejected in Phase 1; incomplete or known-upstream configuration fails validation.
- Firebase initializes only for complete, explicitly enabled owned configuration. Lifecycle work skips Drive/Gmail and Firestore when disabled.
- Added version-controlled Firestore rules/indexes, emulator configuration, and synthetic owner/member/stranger/anonymous tests.
- Added safe ignore rules/placeholders and preserved Phase 0C local-file restore as the recommended one-time Cashew migration route.

Not complete:

- No owned Firebase/Google development or staging project is created or connected.
- Rules tests have not run because this host lacks Java, Firebase CLI, and installed Node test dependencies.
- Consent, fingerprints, iOS scheme/team, web origins/redirects/domain verification, deletion, quotas, retention, monitoring, and incident response require owner/provisioned-environment work.
- Shared-budget email membership remains a risk; rules are not a substitute for a full invitation/role/server-authority design.

Production remains unconfigured and prohibited. See `14_INFRASTRUCTURE_SEPARATION.md`.
