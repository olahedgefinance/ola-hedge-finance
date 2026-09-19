# Phase 1B Firebase Development Integration Plan

> Execute in this branch with TDD and evidence-first verification. Do not deploy Firestore rules until every local rule test passes and the target is re-verified.

## Task 1: Lock the development configuration contract

- Add failing tests for the exact development project allowlist.
- Add independent identity, Drive, and Gmail gates.
- Add failing tests proving Drive/Gmail stay disabled and basic identity remains usable.
- Implement the smallest typed configuration changes.

## Task 2: Restrict Google authorization scopes

- Add a pure scope builder with tests.
- Prove identity requests only profile/email.
- Prove Drive/Gmail scopes appear only behind their explicit gates.
- Update existing sign-in and cloud lifecycle call sites to use the separated capabilities.

## Task 3: Remove anonymous feedback authentication

- Replace anonymous sign-in with an existing non-anonymous Firebase session check.
- Keep feedback fail-closed if no authenticated session exists.
- Add source guards for anonymous-auth regression.

## Task 4: Harden and test Firestore rules

- Expand tests for owner/member/stranger/anonymous behavior.
- Add malformed owner/email/members cases.
- Add owner-field immutability, member escalation, nested transaction, delete/recreate, feedback, and unmatched-path cases.
- Tighten rules only as required by those tests.

## Task 5: Configure the ignored development web environment

- Create an ignored local Dart-defines JSON with console-verified public client values.
- Keep it out of Git output and documentation.
- Build the web target using this file.

## Task 6: Provision and run the emulator toolchain

- Prefer a repository-local Java runtime and Firebase test dependencies.
- Request only the network/filesystem permissions required to acquire them.
- Run the full rules suite against the local Firestore emulator.
- If the toolchain remains unavailable, stop before deployment and document exact owner commands.

## Task 7: Deploy only after all gates pass

- Authenticate without storing credentials in the repository.
- verify the CLI target and project ID immediately before deployment.
- deploy only `firestore:rules` to `ola-hedge-finance-dev`.
- read the deployed rules back from the console and verify they match the tested policy.

## Task 8: Full regression and documentation

- Run focused tests, full Flutter tests, analyzer, web release build, infrastructure scans, and schema/migration diff.
- Update `14_INFRASTRUCTURE_SEPARATION.md`.
- Create `15_FIREBASE_DEV_INTEGRATION.md` with evidence, limitations, exact commands, and one final verdict.
- Commit logical, reviewable checkpoints without pushing or rewriting history.

