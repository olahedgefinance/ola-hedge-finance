# Phase 1B Firebase Development Integration Design

Date: 2026-09-19

Branch: `phase-1b/firebase-dev-integration`

Starting revision: `9637affa1e540b1ce13fa0cb74d336f38d90cb24`

## Goal

Connect the web development build to the owner-controlled Firebase development project without enabling production, native Firebase apps, Drive, Gmail, anonymous authentication, or unrelated cloud services. Firestore rules may be deployed only after their complete emulator suite passes and the active target is independently verified as `ola-hedge-finance-dev`.

## Verified owner-controlled target

The Firebase console was inspected directly. It reports:

- project display name: `OLA HEDGE FINANCE Dev`
- project ID: `ola-hedge-finance-dev`
- web app: `ÓLA HEDGE FINANCE Web Dev`
- Firestore database: `(default)`
- Firestore location: `northamerica-northeast2`
- deployed Firestore policy at the start of the phase: deny all
- enabled authentication providers: Google only
- Firebase public-facing name: `ÓLA HEDGE FINANCE`

The console project ID matches the required development project ID. Client configuration values are public selectors but will remain in an ignored local Dart-defines file rather than source control or documentation.

## Safety boundaries

1. Development is the only allowed environment.
2. The exact Firebase project ID is allowlisted in code when Firebase is enabled.
3. Default builds remain local-only.
4. Web Firebase configuration is injected with `--dart-define-from-file`; no generated Firebase file is committed.
5. Basic Google identity is separated from Drive and Gmail authorization.
6. Drive and Gmail remain disabled and their scopes are not requested.
7. Anonymous Firebase Auth is not used. Feedback requires an existing non-anonymous Firebase user and never triggers a new sign-in.
8. Firestore rules deny unmatched paths and are exercised in the local emulator before deployment.
9. Deployment requires both a green rules suite and a freshly verified active target.
10. Drift schema/version/migrations, Phase 0C restore logic, native identifiers, visual design, and financial features remain unchanged.

## Authentication and scope model

Google authentication has three independent capability gates:

- identity: profile and email scopes, usable for Firebase Auth and shared budgets
- Drive: `drive.appdata` plus optional `drive.file`, disabled in Phase 1B
- Gmail: readonly plus modify, disabled in Phase 1B

Enabling Drive or Gmail without identity is invalid. Identity requires the appropriate platform OAuth client. On web, Firebase and the owned Google web client must both be present. Existing Drive/Gmail code stays in place but fails closed unless its own capability is explicitly enabled.

## Feedback policy

Anonymous Auth remains disabled. Feedback writes are allowed only for authenticated, non-anonymous users. The client uses an already authenticated Firebase session and does not prompt for Google sign-in solely to submit feedback. Firestore allows create only and denies feedback reads, updates, and deletes.

## Firestore authorization model

- A budget creator must be authenticated and create a well-formed owner identity, matching owner email, and members list. The owner is authorized by UID and does not need to appear in the invited-member list.
- The owner and email-listed members can read.
- Members can mutate non-access budget fields and nested transactions.
- Members cannot change the owner, owner email, or membership and cannot delete the budget.
- The owner can manage membership and delete the budget, but cannot rewrite owner identity fields.
- Strangers, anonymous users, malformed owners, unauthenticated callers, and unmatched paths are denied.
- A denied delete prevents a member from using delete/recreate to seize access.
- Feedback is authenticated non-anonymous create-only.

Email membership is retained only as the existing development model. A server-authoritative invitation/role model remains a pre-production requirement.

## Verification and deployment gates

Required local evidence:

- focused configuration and scope tests
- complete Flutter test suite
- analyzer with zero errors under the established baseline
- release web build using the ignored owned development define file
- complete Firestore emulator suite
- source and built-artifact infrastructure guards
- no Drift schema or migration change

Rules deployment is forbidden if Java, Firebase CLI, test dependencies, credentials, target verification, or any test is unavailable/failing. In that case the phase stops with exact owner commands and the existing deny-all cloud policy remains untouched.
