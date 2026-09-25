# Phase 2C Application Identity Architecture

Design approval date: 2026-09-24

Implementation branch: `phase-2c/application-identity-architecture`

Baseline commit: `82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb`

## 1. Purpose and boundaries

Phase 2C replaces inherited application identifiers with an explicit development, staging, and production identity architecture for ÓLA HEDGE FINANCE. It establishes native build variants and Web/PWA metadata without creating external infrastructure or changing financial behaviour.

This phase does not create Firebase projects or apps, OAuth clients, Apple identifiers, domains, signing credentials, store records, logos, icons, product features, AI integrations, or Supabase resources. It does not change Drift schema version 47, migrations, transactions, budgets, accounts, recurrence, financial calculations, imports, exports, or backup data formats.

## 2. Approved identity

These values are owner-approved application identity, not evidence that matching external resources have been registered.

| Environment | Android application ID | iOS bundle identifier |
|---|---|---|
| Development | `com.olahedgefinance.app.dev` | `com.olahedgefinance.app.dev` |
| Staging | `com.olahedgefinance.app.staging` | `com.olahedgefinance.app.staging` |
| Production | `com.olahedgefinance.app` | `com.olahedgefinance.app` |

| Web/product field | Approved value |
|---|---|
| Full product name | `ÓLA HEDGE FINANCE` |
| Short product name | `ÓLA HEDGE` |
| Internal slug | `ola-hedge-finance` |
| Intended future domain | `olahedgefinance.com` |
| GitHub organisation | `olahedgefinance` |
| Repository | `ola-hedge-finance` |
| Existing Firebase development project | `ola-hedge-finance-dev` |

The intended domain is reserved product information only. Phase 2C must not emit a canonical URL, PWA URL identity, app-link host, OAuth redirect, or associated domain that assumes the domain is configured.

## 3. Externally registered infrastructure

The following external state is known:

- Firebase project `ola-hedge-finance-dev` exists.
- Its Web development app and Google identity flow have already been verified through ignored local Dart defines.
- The verified Web development profile requests profile and email identity scopes only.
- Google Drive and Gmail are disabled.
- Firestore development rules exist in the repository and are deployed to the development project's `(default)` database.

The following external state does not yet exist or has not been supplied:

- Firebase staging and production projects;
- staging or production Firebase apps on any platform;
- Android Firebase apps for the approved native application IDs;
- iOS Firebase apps for the approved native bundle identifiers;
- Android signing identities and Firebase SHA-1/SHA-256 registrations for the three environments;
- Apple Developer Team ownership, App IDs, provisioning profiles, or capabilities for the approved bundle identifiers;
- native Google OAuth clients or iOS reverse-client URL schemes;
- a configured production domain, authorized production origins, Digital Asset Links, or Apple association file;
- App Store and Play Console application records.

Phase 2C records these as owner actions and does not synthesize their values.

## 4. Inherited identity audit

### Android

- `budget/android/app/build.gradle` uses `com.budget.tracker_app` as its sole `applicationId` and has no product flavors or explicit namespace.
- Main, debug, and profile manifests declare `package="com.budget.tracker_app"`.
- `MainActivity` and four home-widget providers declare `package com.budget.tracker_app` while their files live under `kotlin/com/example/budget`.
- The application label has already been changed to `ÓLA HEDGE FINANCE`.
- Google Services is applied only when an owner-supplied configuration file exists; no Google Services file is tracked or present.
- No active Android app-link host is registered.

### iOS

- Runner uses `com.budget.tracker-app` in Debug, Profile, and Release.
- RunnerTests uses `com.budget.budget.RunnerTests`.
- The project contains the inherited Apple development team identifier `HCL9V2D3XY`.
- The display name and permission copy already use `ÓLA HEDGE FINANCE`; `CFBundleName` remains `budget`.
- Runner entitlements are empty.
- There is no active OAuth URL scheme, associated domain, or `GoogleService-Info.plist`.
- The project has one Runner scheme and only the standard Debug, Profile, and Release configurations.

### Web/PWA

- The PWA and HTML metadata already use `ÓLA HEDGE FINANCE` as the full name.
- The PWA `short_name` and typed Flutter `shortName` incorrectly repeat the full name.
- `ola-hedge-finance` already exists as the brand manifest key.
- Existing favicon, loading, launcher, and preview assets remain inherited visual assets awaiting Brand/Figma work.
- No canonical production URL is currently emitted.

### Firebase, OAuth, automation, and scripts

- `budget/dart_defines.dev.local.json` is ignored and selects only `ola-hedge-finance-dev`; Google identity is enabled while Drive, Gmail, and store integration are disabled.
- Active Flutter configuration rejects Firebase projects other than the verified development project.
- Identity scopes are profile and email. Drive and Gmail scopes require independent capability flags.
- Authentication tests cover session restoration, sign-in token hand-off, sign-out, and presentation identity clearing.
- `.github/workflows/firebase-hosting-pull-request.yml` is stale inherited automation that references the original `budget-app-flutter` project and its service-account secret name.
- `scripts/deploy_and_build_windows.bat` performs an unqualified `firebase deploy` and unflavoured native release builds.

## 5. Selected architecture

The selected design uses explicit native build variants, a shared repository identity contract, and tests that compare duplicated platform configuration against that contract. It avoids generated native configuration because Xcode and Gradle do not share a reliable cross-platform configuration loader in this Flutter baseline.

### Identity contract

`budget/brand/brand_manifest.json` is the human-readable identity and provenance contract. It now contains:

- full name, short name, description, and slug;
- the three approved Android application IDs;
- the three approved iOS bundle identifiers;
- intended domain marked as unconfigured;
- existing development Firebase project identity;
- GPL and upstream provenance.

`budget/lib/brand/brand_identity.dart` exposes the full name, short name, description, and slug needed at runtime. Native identifiers remain native build configuration; regression tests enforce consistency with the JSON contract.

### Android

Android now uses:

- namespace `com.olahedgefinance.app`;
- base production `applicationId "com.olahedgefinance.app"`;
- flavor dimension `environment`;
- `development` with suffix `.dev`;
- `staging` with suffix `.staging`;
- `production` with no suffix.

The resulting application IDs exactly match the approved matrix. Kotlin declarations and paths now use `com/olahedgefinance/app`. Manifest package attributes were removed so component resolution follows the Gradle namespace. Application display text remains unchanged.

Google Services remains fail-closed. The plugin is applied only when an ignored owner-supplied root or flavor-specific configuration file exists. Phase 2C adds no such file and registers no Android Firebase app.

### iOS

iOS now uses three shared schemes named `development`, `staging`, and `production`. Each scheme maps to environment-specific configurations:

- `Debug-development`, `Profile-development`, `Release-development`;
- `Debug-staging`, `Profile-staging`, `Release-staging`;
- `Debug-production`, `Profile-production`, `Release-production`.

Runner bundle identifiers match the approved matrix. RunnerTests uses the matching application identifier plus `.RunnerTests`. The Podfile maps every custom configuration to the appropriate debug or release CocoaPods mode.

The inherited Apple team identifier was removed. Phase 2C did not add a replacement team, provisioning profile, URL scheme, associated-domain entitlement, push entitlement, or Firebase plist. Native signing and Google login therefore remain external owner-registration work. The iOS project structure has static regression coverage on Windows, but compilation and signing require later macOS/Xcode verification.

### Web/PWA

The Web/PWA surface uses:

- `name`: `ÓLA HEDGE FINANCE`;
- `short_name`: `ÓLA HEDGE`;
- HTML title, application name, Apple title, and social title: `ÓLA HEDGE FINANCE`;
- internal contract slug: `ola-hedge-finance`.

The PWA `start_url` remains deployment-relative. No manifest `id`, canonical link, production origin, or domain-dependent metadata will be introduced until the production domain and hosting path are configured. Existing visual assets remain in place and will be documented as pending Brand/Figma work.

## 6. Firebase and authentication non-regression boundary

Phase 2C must not modify the ignored development client values or create generated Firebase client files. The following behaviour must remain true:

- Firebase initializes only for `ola-hedge-finance-dev` with complete ignored development configuration.
- Web Google sign-in uses the existing Web client and requests profile/email only.
- Drive and Gmail remain independently disabled.
- Web authentication uses local Firebase persistence.
- sign-out clears Firebase and displayed account identity;
- cancelled Google login remains non-fatal and does not fabricate a session;
- Firestore rules and indexes remain unchanged.

Native identifier changes do not affect the Web OAuth client or Web authorized origins. Native Google login will require separately registered native Firebase/OAuth apps and must not be represented as configured in Phase 2C.

## 7. Infrastructure cleanup

The stale Firebase Hosting pull-request workflow was removed because it targeted original Cashew infrastructure and there is no approved ÓLA Hosting deployment in this phase. The Windows helper no longer has an unqualified Firebase deployment command and uses the explicit Production flavour for native build commands. No deployment was performed.

Infrastructure guards scan active source, native configuration, Web metadata, scripts, and `.github` workflows so original service identities cannot return outside approved legal, migration, and compatibility contexts.

## 8. Compatibility, data, and legal safety

- Drift remains schema version 47.
- Existing database files and backup formats are independent of Android/iOS application identifiers and are not modified.
- New native IDs intentionally install as distinct applications from upstream Cashew; automatic access to another app sandbox must not be expected.
- Historical Cashew backup wording and filenames may remain for import compatibility and are not product identity authority.
- The root GPLv3 licence, original copyright notices, Git history, upstream repository attribution, and source-distribution obligations remain intact.
- README and historical changelog references are provenance or later repository-brand work, not active Firebase/native identity.

## 9. Test-first implementation plan requirements

Implementation began with failing identity/configuration tests that require:

1. the approved environment matrix in the brand contract;
2. exact Android namespace and flavor-derived IDs;
3. canonical Kotlin package declarations and paths;
4. absence of inherited Android manifest package values;
5. exact iOS application and test bundle IDs for all nine configurations;
6. absence of the inherited Apple team identifier;
7. all three iOS schemes and CocoaPods configuration mappings;
8. exact Web/PWA full name, short name, and slug;
9. absence of the old Firebase Hosting workflow identity and unqualified deploy command;
10. unchanged Firebase Dev project restriction, identity scopes, disabled Drive/Gmail defaults, GPL licence, and Drift v47.

The failing tests were run before native/Web configuration changes. After the minimal implementation passed focused tests, the complete verification gate is:

- identity and configuration tests;
- infrastructure guards;
- Firestore emulator rule tests;
- complete Flutter suite with the established `SQLITE3_DLL` environment;
- Flutter analysis using `--no-fatal-infos --no-fatal-warnings` and zero errors;
- Web development release build using the ignored development Dart-define file;
- generated artifact scan for original Firebase/OAuth identities;
- Git diff checks proving no database, migration, or financial logic file changed;
- GPL licence hash and Drift v47 checks.

The owner supplied a historical baseline of 62 Flutter tests. A fresh pre-change run on this branch passed 67/67; five previously committed tests account for the difference. Phase 2C must not reduce the actual 67-test starting count or accept a failing test.

## 10. Implemented file set

Implementation changes are limited to identity, platform configuration, guards, tooling, and documentation:

- `budget/brand/brand_manifest.json`;
- `budget/lib/brand/brand_identity.dart`;
- Android Gradle, manifests, and Kotlin package paths;
- iOS project, schemes, Podfile, and display metadata;
- `budget/web/manifest.json`; `budget/web/index.html` was verified and did not require a change;
- brand and infrastructure regression tests;
- the stale Firebase Hosting workflow and Windows build helper;
- relevant transformation documentation.

Database, migration, financial feature, and Firebase rule files are excluded from implementation changes.

## 11. Owner actions after Phase 2C

After the code-level identity matrix is verified, the owner must separately:

1. provide an owned Apple Developer Team and register the three iOS App IDs;
2. create signing/provisioning assets per iOS environment;
3. register the three Android application IDs in the appropriate consoles and provide signing certificate fingerprints;
4. create native Firebase/OAuth apps only when each environment is approved;
5. add native Google configuration through ignored or managed build-secret channels;
6. configure native URL schemes and app links only after clients and domains exist;
7. create staging and production Firebase projects only in their approved phases;
8. configure and verify `olahedgefinance.com` before adding canonical URLs or app-link associations;
9. replace inherited launcher, splash, favicon, preview, and store artwork during Brand/Figma work;
10. run Android device/emulator and iOS macOS/Xcode build, signing, login, widget, notification, and link verification before release.

## 12. Acceptance criteria

Phase 2C is complete only when the approved identifiers are represented consistently in code and platform configuration; inherited active native/service identifiers are removed; the Web Dev Firebase/Google flow remains build- and test-compatible; Drive and Gmail remain disabled; all verification gates pass; GPL provenance remains intact; Drift remains v47; financial logic is untouched; and unregistered external resources are clearly reported rather than implied.

## 13. Implementation checkpoint before final verification

Implemented in code:

- the brand manifest and typed runtime identity now contain the approved full name, short name, slug, platform identity matrix, intended-but-unconfigured domain, and Development-only Firebase state;
- Android has the `environment` flavour dimension, canonical namespace, exact three application IDs, canonical Kotlin package/path, package-free manifests, and fail-closed optional Google Services detection;
- iOS has nine environment build configurations across Runner, RunnerTests, and the project, three shared schemes, exact bundle identifiers, explicit CocoaPods mappings, and no inherited development team;
- Web/PWA uses `ÓLA HEDGE FINANCE`, `ÓLA HEDGE`, and the contract slug `ola-hedge-finance`, with no manifest `id`, canonical production URL, or assumed domain;
- the inherited Firebase Hosting workflow and unqualified Firebase deployment command are gone; Production Android build helpers specify `--flavor production`;
- regression tests cover identity mappings, absent native credentials/capabilities, untracked service configuration, and inherited infrastructure removal.

Reserved or documented only:

- Firebase Staging and Production projects/apps;
- all native Firebase apps and Google OAuth clients;
- Android signing registrations and certificate fingerprints;
- an Apple Developer Team, App IDs, provisioning profiles, URL schemes, and associated domains;
- `olahedgefinance.com`, hosting, authorized origins, app-link files, and canonical URLs;
- final launcher, splash, favicon, preview, and store artwork.

Cashew-facing names remain only where required for GPL/upstream provenance, historical changelog/backup compatibility, import/migration compatibility, or source references. They are not active native, Firebase, OAuth, deployment, or Web/PWA identity.

At this checkpoint, the iterative complete Flutter suite passes 77/77, up from the fresh 67/67 branch baseline. This is not the final verification record: Firestore emulator tests, analyzer, locked dependency check, Web Development release build, artifact scans, licence hash, Drift v47 proof, and final diff review are recorded only after Task 6 runs them afresh.
