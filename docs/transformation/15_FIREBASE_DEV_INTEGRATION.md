# Phase 1B Firebase Development Integration

Verification date: 2026-09-19

Branch: `phase-1b/firebase-dev-integration`

Starting revision: `9637affa1e540b1ce13fa0cb74d336f38d90cb24`

Official product identity: **ÓLA HEDGE FINANCE**

## 1. Scope and verdict

This phase connects only the web development build to the owner-controlled Firebase development project. It does not create or connect staging/production, change Android or iOS identifiers, enable Drive/Gmail, change Drift, redesign UI, add subscriptions, or add AI.

> Historical/supersession note (2026-09-24): The native-identifier statement describes Phase 1B scope. Phase 2C subsequently implemented the owner-approved Android/iOS identity matrix without connecting native Firebase apps or changing this verified Web Development Firebase/OAuth configuration. See [`16_APPLICATION_IDENTITY_ARCHITECTURE.md`](16_APPLICATION_IDENTITY_ARCHITECTURE.md).

The exact verified project ID is `ola-hedge-finance-dev`. The web app is registered as **ÓLA HEDGE FINANCE Web Dev**. Firestore uses the `(default)` database in `northamerica-northeast2`. The project is on the Spark plan. The Firebase console currently labels the environment type `Unspecified`; the owner should change that label to Development.

The local integration, release build, development startup, and security-rule suite pass. The tested policy is deployed only to the verified development database and its deployed editor content matches the tested repository version. Interactive Google sign-in has not been completed, so the full exit gate remains conditional.

**FIREBASE DEV INTEGRATION CONDITIONALLY READY**

## 2. Service state

| Service | Development state | Notes |
|---|---|---|
| Firebase Core | Configured locally | Initialized only when the validated development configuration enables it |
| Cloud Firestore | Development rules deployed | Emulator-tested policy published only to the verified `(default)` development database |
| Firebase Auth | Google provider enabled | Application uses existing non-anonymous sessions; live smoke pending |
| Google identity | Enabled in local dev config | Requests `profile` and `email` only |
| Anonymous Auth | Disabled by application policy | Rules also reject anonymous-auth tokens |
| Email/password Auth | Not enabled |
| Phone Auth | Not enabled |
| Apple Auth | Not enabled |
| Google Drive | Disabled | Retained code is unreachable unless a separate explicit flag and folder are supplied |
| Gmail | Disabled | Retained code is unreachable unless a separate explicit flag is supplied |
| Firebase Storage | Not enabled/used |
| Analytics | Not enabled/used |
| Crashlytics | Not enabled/used |
| Messaging | Not enabled/used; local notifications remain independent |
| App Check | Not enabled | Required security decision before production |
| Billing/subscriptions | Disabled |
| AI services | Not present |

## 3. Configuration and secret handling

`InfrastructureConfig` now accepts Firebase only when all of the following are true:

- environment is `development`;
- project ID is exactly `ola-hedge-finance-dev`;
- required web public client fields are present;
- the selected values do not match known upstream Cashew infrastructure.

Google identity, Drive, and Gmail are independent capabilities. Identity requires only its web client configuration. Drive additionally requires `OLA_GOOGLE_DRIVE_ENABLED=true` and an owned folder value. Gmail additionally requires `OLA_GMAIL_ENABLED=true`. Both are false in the development profile.

The real public web client configuration is stored only in ignored `budget/dart_defines.dev.local.json`. It is not committed, printed in this document, or embedded in tracked source. `.gitignore` excludes Dart-define JSON, Firebase generated client files, Google services files, service-account material, signing material, and `.firebaserc`.

Firebase web API keys and app identifiers are public selectors rather than server secrets, but they are still kept out of source to prevent accidental environment coupling. Service-account keys, OAuth client secrets, refresh tokens, signing keys, and production data must never be placed in this file or committed.

## 4. Google authentication boundary

`google_auth_scopes.dart` makes the requested scopes explicit:

- identity-only: `profile`, `email`;
- Drive: added only when the Drive capability is explicitly enabled;
- Gmail: added only when the Gmail capability is explicitly enabled.

Firebase sharing uses the identity-only path. The prior anonymous feedback bootstrap was removed; feedback may use only an already-authenticated, non-anonymous session. Background backup, Drive sync, Gmail parsing, and their lifecycle hooks fail closed when disabled.

The release artifact still contains dormant Drive/Gmail scope strings because the reusable feature code remains compiled. Tests and runtime gates prove those scopes are not requested in this development profile. Removing the code would violate the requirement to preserve existing functionality.

Interactive Google Auth remains an owner-assisted test because it opens a real account selector/consent flow. Required checks are successful sign-in, cancellation, sign-out, reload persistence, and confirmation that the consent screen requests identity only.

## 5. Firestore data and rule model

The Firestore schema remains the existing application model:

- `/budgets/{budgetId}`: shared-budget metadata including `owner`, `ownerEmail`, and `members`;
- `/budgets/{budgetId}/transactions/{transactionId}`: synchronized transaction documents;
- `/feedback/{feedbackId}`: feedback submissions.

The client creates a budget with an empty members list, so the owner is authorized independently by immutable owner UID and owner email. Membership is a list of verified email strings. No Drift table, schema version, migration, financial calculation, or backup format changed.

The hardened policy requires a non-anonymous authenticated user with an email. It permits:

- exact-owner creation with well-formed access fields;
- owner or listed-member reads;
- only the owner to change the membership list or delete a budget;
- members to change non-access fields and nested transactions while preserving access fields;
- owner and member list queries matching the actual client query shapes;
- non-anonymous authenticated feedback creation only.

It denies malformed access fields, owner/owner-email mutation, member escalation, member delete/recreate, stranger access, anonymous/unauthenticated access, feedback reads or edits, and every unmatched path.

The committed rules SHA-256 at deployment was `EB947D243B9C146C02C22EEB7F8E2C7DE724D1500E400739D79BBDCA9AD1402E`. `firestore.indexes.json` remains an explicit empty index set because the current query shapes do not require a composite index.

## 6. Emulator security evidence

An isolated repository-local Java 21 runtime and Firebase emulator cache were used; both are ignored. The test command targets the rules and emulator configuration in `budget/firebase.json` and never contacts production data.

All 12 security tests pass:

1. unauthenticated and anonymous-auth clients are denied;
2. authenticated users without an email are denied;
3. owner create/read/content-edit/member-management/delete succeeds;
4. malformed owner, email, and members fields are rejected;
5. owner identity is immutable and membership stays a list;
6. a member can read, edit non-access fields, and use nested transactions;
7. a member cannot alter access, delete, or delete-recreate;
8. a stranger cannot use parent or nested data;
9. the client owner/member list queries satisfy the list policy;
10. malformed stored access fields grant no parent or nested access;
11. feedback is non-anonymous authenticated create-only;
12. unmatched paths are denied.

## 7. Build and runtime verification

| Gate | Result |
|---|---|
| Project identity | PASS — exact `ola-hedge-finance-dev` verified in Firebase console |
| Configuration/scopes/source guards | PASS |
| Full Flutter test suite | PASS — 60/60 |
| Firestore emulator suite | PASS — 12/12 |
| Analyzer baseline | PASS — zero errors; 5,251 historical warning/info findings allowed by the established command |
| Release web build with development config | PASS |
| Development release-mode startup | PASS — served locally, Flutter mounted, zero browser errors/warnings |
| Built-artifact upstream identity scan | PASS — no old Firebase/OAuth identity found |
| Drift v47/migrations diff | PASS — no changes |
| Firestore rules publication | PASS — new development revision at 2026-09-19 01:11 local time |
| Deployed/repository rule comparison | PASS — normalized editor content exactly matches the tested policy |
| Live Google Auth smoke | PENDING — owner interaction required |
| Android/iOS | HISTORICAL PHASE 1B RESULT — native identifiers were out of scope; Phase 2C later configured code identities only |

Representative commands, run from `budget/` with the pinned Flutter SDK and isolated caches:

```powershell
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter build web --release --no-pub --dart-define-from-file=dart_defines.dev.local.json
flutter run -d web-server --release --no-pub --dart-define-from-file=dart_defines.dev.local.json
```

From `budget/firebase-tests/`, use the committed package script through `firebase emulators:exec`. Java, Firebase emulator, Node package, and package-manager caches may be local/CI-managed but must not be committed.

## 8. Publication and rollback record

Completed publication controls:

1. active Firebase console project ID verified as exactly `ola-hedge-finance-dev`;
2. tracked rules hash recorded above;
3. all 12 emulator tests rerun successfully before publication;
4. prior deny-all revision retained in Firebase revision history;
5. only `budget/firestore.rules` was published to the `(default)` database;
6. console success message and new 01:11 revision verified;
7. deployed editor text compared with the tested policy and matched after normalization;
8. no composite indexes were deployed.

If unexpected access occurs, restore the retained deny-all revision immediately and investigate locally. No production or staging target was selected, and no service-account material or real financial records were uploaded.

## 9. Remaining security limitations

- Email-list membership is client-managed and weaker than server-issued roles or invitations.
- There is no authoritative backend for invitations, account linking, ownership transfer, revocation, abuse/rate limiting, or audit history.
- App Check is not enabled.
- Feedback has no server-side rate limit or moderation pipeline.
- Google Auth has not been interactively smoke-tested.
- The Firebase console environment label is not yet Development.
- Authorized-domain, consent-branding, privacy-policy, deletion, and support flows need release review.
- Dormant Drive/Gmail feature code remains compiled, though disabled by configuration.
- The web configuration is development-only; no staging/production isolation has been established.

These are acceptable for a blocked development checkpoint, not for production deployment.

## 10. Owner actions required

1. Complete the interactive Google identity smoke test and verify only profile/email consent, cancellation, authenticated identity, and sign-out.
2. Label the Firebase project environment Development.
3. Confirm authorized development domains and OAuth support/privacy branding.
4. Decide the future invitation, revocation, ownership-transfer, account-deletion, audit, rate-limit, and App Check architecture.
5. Keep real user financial data out of this development project.
6. Defer Android/iOS app registration, staging, production, Drive/Gmail, billing, and AI until separately approved phases.

## 11. Files changed in Phase 1B

- Hardened `budget/firestore.rules` and expanded its emulator tests.
- Added explicit Google scope composition in `budget/lib/config/google_auth_scopes.dart`.
- Tightened `InfrastructureConfig` to the exact development project and independent identity/Drive/Gmail flags.
- Routed Firebase Auth through identity-only sign-in and removed anonymous feedback sign-in.
- Gated Drive backup/sync and Gmail parsing independently.
- Added ignored-tooling protection and reproducible rules-test lock/workspace files.
- Added this integration record and updated the Phase 1 separation record.

No dependency upgrade, database schema change, historical migration rewrite, financial-logic change, native identifier change, UI redesign, staging/production connection, subscription implementation, or AI work was performed.
