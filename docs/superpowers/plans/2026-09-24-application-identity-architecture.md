# Application Identity Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish explicit Development, Staging, and Production application identities for Android and iOS, update the Web/PWA identity, and remove inherited deployment coupling without changing financial behaviour or the working Web Development Firebase/OAuth environment.

**Architecture:** Treat `budget/brand/brand_manifest.json` as the human-readable identity contract, with Flutter platform configuration implementing the same approved identifiers. Android uses one base namespace plus an `environment` product-flavour dimension. iOS uses nine build configurations grouped into three shared schemes. Web remains a single build target whose Development Firebase values continue to arrive only through the existing ignored Dart-defines file. Static regression tests make platform identifiers, external-service boundaries, provenance, and database immutability executable.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, Gradle 7.4/Android Gradle Plugin 7.3.1, Kotlin, Xcode project/schemes, CocoaPods, JSON, HTML, `flutter_test`, Drift/SQLite, Firebase emulator tooling, PowerShell.

**Spec:** `docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md`

## Global Constraints

- Preserve Git history, GPLv3, original copyright notices, and upstream provenance.
- Keep Drift schema version 47 and do not edit database tables, migrations, financial models, transaction logic, budget logic, account logic, recurring logic, or calculations.
- Preserve the current ignored `budget/dart_defines.dev.local.json`; never print its secret values or commit it.
- Keep Web Development Firebase restricted to project `ola-hedge-finance-dev`.
- Keep Google authentication identity-only: `openid`, `email`, and `profile`; Drive and Gmail remain disabled.
- Do not create Firebase Production/Staging projects, native Firebase apps, OAuth clients, Apple signing assets, app-store records, domains, icons, or logos.
- Do not run a Firebase deploy, publish artifacts, push branches, or contact upstream.
- Do not upgrade dependencies.
- Use `apply_patch` for every hand-authored file change. Preserve unrelated user changes if any appear.
- After every task, review `git status --short`, `git diff --check`, and the scoped diff before committing.

## Review Focus

Every implementation task must guard against these failure modes:

1. Android flavour IDs are not exact, or suffixes are duplicated.
2. Xcode schemes point to missing or mismatched build configurations.
3. Web Development Firebase/OAuth behaviour changes or secrets enter source control.
4. Active automation still targets original Cashew infrastructure.
5. Database versioning, financial behaviour, or GPL provenance changes.

## Tool Variables Used by Verification Steps

Run commands from the repository root unless a step says otherwise. In PowerShell, initialise the following task-specific variables in each fresh shell:

```powershell
$repo = 'C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work\Cashew'
$budget = Join-Path $repo 'budget'
$work = Split-Path $repo -Parent
$flutter = Join-Path $work 'flutter-sdk\bin\flutter.bat'
$sqliteDll = Join-Path $work 'tooling\sqlite-3.53.4-win-x64\sqlite3.dll'
$bundledGit = 'C:\Users\Oluwa\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git'
$env:Path = "$($bundledGit)\cmd;$($bundledGit)\mingw64\bin;$($bundledGit)\usr\bin;$env:Path"
$env:GIT_EXEC_PATH = "$($bundledGit)\mingw64\bin"
```

Before executing the plan, resolve `$flutter` and confirm it points to the pinned SDK. If the relative expression differs on this machine, use the already verified absolute path:

```text
C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work\flutter-sdk\bin\flutter.bat
```

---

## Task 1: Make the Approved Brand and Web Identity Executable

**Files:**

- Modify: `budget/test/brand/brand_manifest_contract_test.dart`
- Modify: `budget/test/brand/brand_identity_test.dart`
- Modify: `budget/brand/brand_manifest.json`
- Modify: `budget/lib/brand/brand_identity.dart`
- Modify: `budget/web/manifest.json`
- Verify: `budget/web/index.html`

- [ ] **Step 1: Add failing identity-contract assertions**

Update the tests so they require:

```dart
expect(identity.productName, 'ÓLA HEDGE FINANCE');
expect(identity.shortName, 'ÓLA HEDGE');
expect(identity.slug, 'ola-hedge-finance');
```

Extend the manifest contract assertions to require explicit environment identity data equivalent to:

```json
{
  "android": {
    "development": "com.olahedgefinance.app.dev",
    "staging": "com.olahedgefinance.app.staging",
    "production": "com.olahedgefinance.app"
  },
  "ios": {
    "development": "com.olahedgefinance.app.dev",
    "staging": "com.olahedgefinance.app.staging",
    "production": "com.olahedgefinance.app"
  },
  "web": {
    "slug": "ola-hedge-finance",
    "intendedDomain": "olahedgefinance.com",
    "domainConfigured": false
  }
}
```

Also assert that the manifest records Firebase Development project `ola-hedge-finance-dev`, marks Staging and Production Firebase as unconfigured, and retains GPL/upstream provenance.

- [ ] **Step 2: Run the focused tests and confirm they fail for the new contract**

```powershell
Set-Location $budget
& $flutter test test/brand/brand_identity_test.dart test/brand/brand_manifest_contract_test.dart
```

Expected: failure because the short name is still the full name, no Dart `slug` accessor exists, and the environment identity contract is absent.

- [ ] **Step 3: Implement the smallest brand contract change**

Update `brand_manifest.json` without removing provenance. Add only approved values and explicit `configured: false`/equivalent markers for infrastructure that does not exist.

Update `BrandIdentity` to expose the existing internal brand key as an immutable `slug` property. Do not introduce environment selection into visual components.

Change `budget/web/manifest.json` to:

```json
{
  "name": "ÓLA HEDGE FINANCE",
  "short_name": "ÓLA HEDGE"
}
```

Preserve the rest of the manifest and existing placeholder visual assets. Do not add a PWA `id`, canonical URL, or production-domain metadata.

Verify `budget/web/index.html` already contains the approved full title/description; change it only if a targeted test demonstrates a mismatch.

- [ ] **Step 4: Re-run focused tests**

```powershell
Set-Location $budget
& $flutter test test/brand/brand_identity_test.dart test/brand/brand_manifest_contract_test.dart
```

Expected: PASS.

- [ ] **Step 5: Review and commit**

```powershell
Set-Location $repo
git diff --check
git diff -- budget/brand/brand_manifest.json budget/lib/brand/brand_identity.dart budget/web/manifest.json budget/web/index.html budget/test/brand
git add -- budget/brand/brand_manifest.json budget/lib/brand/brand_identity.dart budget/web/manifest.json budget/web/index.html budget/test/brand/brand_identity_test.dart budget/test/brand/brand_manifest_contract_test.dart
git commit -m "feat: establish application identity contract"
```

---

## Task 2: Implement Android Environment Flavours and Namespace

**Files:**

- Create: `budget/test/config/application_identity_architecture_test.dart`
- Modify: `budget/android/app/build.gradle`
- Modify: `budget/android/app/src/main/AndroidManifest.xml`
- Modify: `budget/android/app/src/debug/AndroidManifest.xml`
- Modify: `budget/android/app/src/profile/AndroidManifest.xml`
- Create: `budget/android/app/src/main/kotlin/com/olahedgefinance/app/MainActivity.kt`
- Create: `budget/android/app/src/main/kotlin/com/olahedgefinance/app/PlusWidgetProvider.kt`
- Create: `budget/android/app/src/main/kotlin/com/olahedgefinance/app/TransferWidgetProvider.kt`
- Create: `budget/android/app/src/main/kotlin/com/olahedgefinance/app/NetWorthWidgetProvider.kt`
- Create: `budget/android/app/src/main/kotlin/com/olahedgefinance/app/NetWorthPlusWidgetProvider.kt`
- Delete: corresponding files under `budget/android/app/src/main/kotlin/com/example/budget/`

- [ ] **Step 1: Add failing Android architecture tests**

The new static test must parse/read the actual Gradle, manifests, and Kotlin files and assert all of the following:

```text
namespace: com.olahedgefinance.app
flavor dimension: environment
development applicationId: com.olahedgefinance.app.dev
staging applicationId: com.olahedgefinance.app.staging
production applicationId: com.olahedgefinance.app
```

Guard exactness, not mere substring presence. Assert there is one base `applicationId "com.olahedgefinance.app"`, suffixes are exactly `.dev` and `.staging`, Production has no suffix, and none of the three manifests has a `package=` attribute.

Assert every Kotlin source declares:

```kotlin
package com.olahedgefinance.app
```

Assert the old Kotlin path and identifiers `com.budget.tracker_app` and `com.example.budget` no longer exist in active Android sources.

- [ ] **Step 2: Run the new test and confirm it fails**

```powershell
Set-Location $budget
& $flutter test test/config/application_identity_architecture_test.dart
```

Expected: failure on the inherited Android application ID, missing flavour dimension, manifest package attributes, and Kotlin path.

- [ ] **Step 3: Add the explicit Android flavour model**

In `android/app/build.gradle`, add:

```groovy
android {
    namespace "com.olahedgefinance.app"

    defaultConfig {
        applicationId "com.olahedgefinance.app"
    }

    flavorDimensions "environment"
    productFlavors {
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
        }
        production {
            dimension "environment"
        }
    }
}
```

Retain current SDK/minimum/version settings and plugins. Update any conditional Google Services plugin detection so it recognises a future config at either `android/app/google-services.json` or a flavour source set such as `android/app/src/development/google-services.json`, but do not add any configuration file or fabricate credentials.

- [ ] **Step 4: Migrate Android package ownership**

Remove `package="com.budget.tracker_app"` from all three manifests.

Recreate the five Kotlin files at `com/olahedgefinance/app/`, preserving their class bodies exactly and changing only the package declaration. Delete the old files only after comparing them. Manifest component names may stay relative because they resolve against the new namespace.

- [ ] **Step 5: Re-run the Android test and inspect Gradle variant identity**

```powershell
Set-Location $budget
& $flutter test test/config/application_identity_architecture_test.dart
Set-Location (Join-Path $budget 'android')
.\gradlew.bat :app:tasks --all
```

Expected: test PASS; Gradle lists Development, Staging, and Production assemble tasks with no configuration failure.

- [ ] **Step 6: Review and commit**

```powershell
Set-Location $repo
git diff --check
git diff -- budget/android budget/test/config/application_identity_architecture_test.dart
git add -- budget/android budget/test/config/application_identity_architecture_test.dart
git commit -m "feat: add Android environment identities"
```

---

## Task 3: Implement iOS Environment Configurations and Shared Schemes

**Files:**

- Modify: `budget/test/config/application_identity_architecture_test.dart`
- Modify: `budget/ios/Runner.xcodeproj/project.pbxproj`
- Modify: `budget/ios/Runner/Info.plist`
- Modify: `budget/ios/Podfile`
- Create: `budget/ios/Runner.xcodeproj/xcshareddata/xcschemes/development.xcscheme`
- Create: `budget/ios/Runner.xcodeproj/xcshareddata/xcschemes/staging.xcscheme`
- Create: `budget/ios/Runner.xcodeproj/xcshareddata/xcschemes/production.xcscheme`
- Delete: `budget/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` only if the custom schemes fully replace it and Flutter discovery succeeds

- [ ] **Step 1: Extend the static architecture test for iOS**

Require the project to contain exactly these Runner bundle-ID mappings:

| Configuration | Runner bundle ID | RunnerTests bundle ID |
|---|---|---|
| Debug-development | `com.olahedgefinance.app.dev` | `com.olahedgefinance.app.dev.RunnerTests` |
| Profile-development | `com.olahedgefinance.app.dev` | `com.olahedgefinance.app.dev.RunnerTests` |
| Release-development | `com.olahedgefinance.app.dev` | `com.olahedgefinance.app.dev.RunnerTests` |
| Debug-staging | `com.olahedgefinance.app.staging` | `com.olahedgefinance.app.staging.RunnerTests` |
| Profile-staging | `com.olahedgefinance.app.staging` | `com.olahedgefinance.app.staging.RunnerTests` |
| Release-staging | `com.olahedgefinance.app.staging` | `com.olahedgefinance.app.staging.RunnerTests` |
| Debug-production | `com.olahedgefinance.app` | `com.olahedgefinance.app.RunnerTests` |
| Profile-production | `com.olahedgefinance.app` | `com.olahedgefinance.app.RunnerTests` |
| Release-production | `com.olahedgefinance.app` | `com.olahedgefinance.app.RunnerTests` |

Assert:

- inherited IDs `com.budget.tracker-app` and `com.budget.budget.RunnerTests` are absent;
- inherited team `HCL9V2D3XY` is absent;
- the three shared scheme files exist;
- each scheme maps Run/Test/Analyze to `Debug-<environment>`, Profile to `Profile-<environment>`, and Archive to `Release-<environment>`;
- the Podfile maps all nine configurations to `:debug` or `:release` correctly;
- no GoogleService plist, URL scheme, associated domain, signing team, or entitlement is invented.

- [ ] **Step 2: Run the static test and confirm it fails**

```powershell
Set-Location $budget
& $flutter test test/config/application_identity_architecture_test.dart
```

Expected: failure on inherited IDs, missing environment configurations/schemes, and inherited signing team.

- [ ] **Step 3: Create nine Xcode build configurations**

Duplicate the semantic content of the existing Debug/Profile/Release configurations into the nine named configurations. Do not change deployment targets, frameworks, entitlements, or build settings unrelated to identity.

Set exact Runner and RunnerTests IDs from the table. Remove `DEVELOPMENT_TEAM = HCL9V2D3XY;` without substituting a new team. Keep automatic/manual signing settings otherwise unchanged unless Xcode syntax requires removal of an orphaned setting.

Set `CFBundleName`/the visible non-localised bundle name in `Info.plist` to `ÓLA HEDGE`, while keeping `CFBundleDisplayName` as `ÓLA HEDGE FINANCE`.

- [ ] **Step 4: Add schemes and CocoaPods mappings**

Create shared schemes `development`, `staging`, and `production` using the configuration mapping asserted above. Ensure every scheme targets the existing Runner target and test action includes RunnerTests.

Map the Podfile configurations explicitly:

```ruby
'Debug-development' => :debug,
'Profile-development' => :release,
'Release-development' => :release,
'Debug-staging' => :debug,
'Profile-staging' => :release,
'Release-staging' => :release,
'Debug-production' => :debug,
'Profile-production' => :release,
'Release-production' => :release,
```

Do not run CocoaPods on Windows. The project file and scheme XML are verified statically here and must later be opened/archived on an owner-configured macOS/Xcode environment.

- [ ] **Step 5: Re-run the static architecture tests**

```powershell
Set-Location $budget
& $flutter test test/config/application_identity_architecture_test.dart
```

Expected: PASS.

- [ ] **Step 6: Review and commit**

```powershell
Set-Location $repo
git diff --check
git diff -- budget/ios budget/test/config/application_identity_architecture_test.dart
git add -- budget/ios budget/test/config/application_identity_architecture_test.dart
git commit -m "feat: add iOS environment identities"
```

---

## Task 4: Remove Inherited Deployment Coupling and Strengthen Guards

**Files:**

- Modify: `budget/test/config/original_infrastructure_guard_test.dart`
- Modify: `budget/test/brand/brand_manifest_contract_test.dart`
- Modify: `scripts/deploy_and_build_windows.bat`
- Delete: `.github/workflows/firebase-hosting-pull-request.yml`

- [ ] **Step 1: Make stale infrastructure fail the guard tests**

Expand the infrastructure guard to inspect repository-root `.github` and `scripts` in addition to `budget/lib`, `budget/android`, `budget/ios`, and `budget/web`.

Remove allowances for `com.budget.tracker_app` and `com.budget.tracker-app` from active platform configuration. Preserve a narrow allowlist only for compatibility/provenance locations documented by the spec.

Add assertions that:

- no active workflow references `budget-app-flutter` or `FIREBASE_SERVICE_ACCOUNT_BUDGET_APP_FLUTTER`;
- no deployment script contains unqualified `firebase deploy`;
- Android release build commands include `--flavor production`;
- `.github/workflows/firebase-hosting-pull-request.yml` is absent;
- no ignored local secrets are tracked.

- [ ] **Step 2: Run focused guards and confirm they fail on inherited automation**

```powershell
Set-Location $budget
& $flutter test test/config/original_infrastructure_guard_test.dart test/brand/brand_manifest_contract_test.dart
```

Expected: failure on the old Firebase Hosting workflow, unqualified deploy command, and unflavoured Android release commands.

- [ ] **Step 3: Remove only the unsafe inherited automation**

Delete `.github/workflows/firebase-hosting-pull-request.yml`; it is bound to the original Firebase project and secret and cannot safely be repurposed before owner registration.

In `scripts/deploy_and_build_windows.bat`:

- remove the unqualified `firebase deploy` operation entirely;
- add `--flavor production` to Android APK/App Bundle release builds;
- keep unrelated useful local build commands intact;
- do not add a new deployment target or service account.

- [ ] **Step 4: Re-run guard tests**

```powershell
Set-Location $budget
& $flutter test test/config/original_infrastructure_guard_test.dart test/brand/brand_manifest_contract_test.dart test/config/application_identity_architecture_test.dart
```

Expected: PASS.

- [ ] **Step 5: Review and commit**

```powershell
Set-Location $repo
git diff --check
git diff -- .github scripts budget/test/config/original_infrastructure_guard_test.dart budget/test/brand/brand_manifest_contract_test.dart
git add -- .github scripts budget/test/config/original_infrastructure_guard_test.dart budget/test/brand/brand_manifest_contract_test.dart
git commit -m "chore: remove inherited deployment identity"
```

---

## Task 5: Reconcile Transformation Documentation With the Implemented Architecture

**Files:**

- Modify: `docs/transformation/14_PHASE_2B_INFRASTRUCTURE_HARDENING.md`
- Modify: `docs/transformation/15_PHASE_2B_COMPLETION_REPORT.md`
- Modify: `docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md`

- [ ] **Step 1: Identify provisional identifiers superseded by owner approval**

```powershell
Set-Location $repo
rg -n "com\.budget|tracker-app|tracker_app|budget-app-flutter|Firebase Production|Firebase Staging|olahedgefinance\.com" docs/transformation/14_PHASE_2B_INFRASTRUCTURE_HARDENING.md docs/transformation/15_PHASE_2B_COMPLETION_REPORT.md docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md
```

Classify every hit as historical evidence, compatibility/provenance, or a statement now superseded by Phase 2C.

- [ ] **Step 2: Update documentation without rewriting history**

In Phase 2B documents, preserve historical results but add a clear supersession note where provisional/native IDs are no longer current.

In the Phase 2C architecture document, record:

- the files actually changed;
- final Android, iOS, and Web/PWA mappings;
- what is implemented versus reserved/documented only;
- the unchanged Firebase/OAuth boundary;
- required external registrations;
- remaining Cashew-facing compatibility/provenance identifiers;
- tests added/changed;
- an explicit statement that Drift remains v47 and financial logic was untouched.

Do not claim verification results until Task 6 produces fresh evidence.

- [ ] **Step 3: Validate documentation and commit**

```powershell
Set-Location $repo
rg -n "TBD|TODO|PLACEHOLDER|fill in" docs/transformation/14_PHASE_2B_INFRASTRUCTURE_HARDENING.md docs/transformation/15_PHASE_2B_COMPLETION_REPORT.md docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md
git diff --check
git diff -- docs/transformation
git add -- docs/transformation/14_PHASE_2B_INFRASTRUCTURE_HARDENING.md docs/transformation/15_PHASE_2B_COMPLETION_REPORT.md docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md
git commit -m "docs: record application identity migration"
```

Expected: no unresolved placeholders; historical statements remain clearly labelled rather than silently altered.

---

## Task 6: Run the Complete Regression and Build Verification Matrix

**Files:**

- Modify after evidence exists: `docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md`

- [ ] **Step 1: Confirm the toolchain and dependency lock remain pinned**

```powershell
Set-Location $budget
& $flutter --version
& $flutter pub get --enforce-lockfile
git diff --exit-code -- pubspec.lock
```

Expected: Flutter 3.19.6/Dart 3.3.4; dependency resolution succeeds without modifying `pubspec.lock`.

- [ ] **Step 2: Run identity, infrastructure, auth, and configuration regressions**

```powershell
Set-Location $budget
& $flutter test test/brand test/config test/auth/app_auth_session_test.dart
```

Expected: PASS, including:

- Firebase Development project remains exactly `ola-hedge-finance-dev`;
- Production Firebase remains rejected/unconfigured;
- Staging Firebase remains unconfigured;
- Google scopes remain identity-only;
- Drive/Gmail remain false;
- session persistence, sign-out, identity clearing, and cancelled-login behaviour remain intact.

- [ ] **Step 3: Run the complete Flutter test suite with SQLite**

```powershell
Set-Location $budget
$env:SQLITE3_DLL = $sqliteDll
& $flutter test
```

Expected: no regression from the established 62/62 baseline. Record the new exact pass count if new tests increase the total.

- [ ] **Step 4: Run Firestore rules tests**

```powershell
$nodeRoot = Join-Path $repo 'tooling\node20\node-v20.20.2-win-x64'
$javaHome = Join-Path $repo 'tooling\temurin-jdk21\jdk-21.0.12.1+1'
$env:JAVA_HOME = $javaHome
$env:Path = "$nodeRoot;$($nodeRoot)\node_modules\corepack\shims;$($javaHome)\bin;$env:Path"
Set-Location (Join-Path $budget 'firebase-tests')
& (Join-Path $nodeRoot 'node_modules\corepack\shims\pnpm.cmd') test
```

Expected: Firestore development rules tests PASS against the isolated `ola-hedge-finance-rules-test` emulator project. No deployment occurs.

- [ ] **Step 5: Run Flutter analysis under the established baseline policy**

```powershell
Set-Location $budget
& $flutter analyze --no-fatal-infos --no-fatal-warnings
```

Expected: exit code 0. Record informational/warning counts exactly if the repository baseline still contains them; do not conceal new errors.

- [ ] **Step 6: Build Web Development release with the existing ignored configuration**

First verify that the local defines file exists and remains ignored without displaying its contents:

```powershell
Set-Location $repo
Test-Path -LiteralPath (Join-Path $budget 'dart_defines.dev.local.json')
git check-ignore budget/dart_defines.dev.local.json
git status --short --ignored budget/dart_defines.dev.local.json
```

Then build:

```powershell
Set-Location $budget
& $flutter build web --release --dart-define-from-file=dart_defines.dev.local.json
```

Expected: PASS. Do not print or copy the defines file.

- [ ] **Step 7: Scan source and build output for identity regressions without exposing secrets**

```powershell
Set-Location $repo
rg -n "budget-app-flutter|FIREBASE_SERVICE_ACCOUNT_BUDGET_APP_FLUTTER|com\.budget\.tracker_app|com\.budget\.tracker-app|com\.example\.budget" .github scripts budget/android budget/ios budget/web budget/build/web
rg -n "ola-hedge-finance-dev" budget/build/web
rg -n "drive|gmail" budget/lib/config budget/build/web
```

Interpret hits carefully: minified build output may contain feature labels or disabled code. The executable config tests, not string absence alone, determine whether Drive/Gmail are enabled. The old package identifiers must be absent from active platform source/build output.

- [ ] **Step 8: Prove database, financial, and provenance immutability**

```powershell
Set-Location $repo
rg -n "schemaVersionGlobal\s*=\s*47|schemaVersion.*47" budget/lib
Get-FileHash -Algorithm SHA256 LICENSE
git diff --name-only 67aa891c2304c19120493b8adb6a066dee37b1dd -- budget/lib budget/test | Sort-Object
git diff --stat 67aa891c2304c19120493b8adb6a066dee37b1dd
```

Expected:

- schema remains v47;
- `LICENSE` SHA-256 remains `f98d1bda4e0515a2a865ae338f0d0f25aa34925d`;
- production Dart changes are limited to `budget/lib/brand/brand_identity.dart`;
- no database, migration, transaction, budget, account, recurring, calculation, AI, or Supabase file changed.

- [ ] **Step 9: Record only fresh verification evidence**

Update the Phase 2C document with exact commands, exit results, test counts, analysis result, Web build result, branch name, and the pre-report implementation commit hash. If any check fails, do not document success: use `superpowers:systematic-debugging`, add/reproduce a failing test, make the smallest in-scope correction, and rerun the affected and complete checks.

- [ ] **Step 10: Commit verification documentation and run a final clean-tree check**

```powershell
Set-Location $repo
git diff --check
git add -- docs/transformation/16_APPLICATION_IDENTITY_ARCHITECTURE.md
git commit -m "docs: record Phase 2C verification"
git status --short --branch
git rev-parse HEAD
```

Expected: clean working tree on `phase-2c/application-identity-architecture`. The returned commit is the hash reported to the owner.

---

## Task 7: Final Scope and Evidence Review

**Files:** None unless the review finds an error that must be corrected through the relevant earlier task.

- [ ] **Step 1: Review the complete change set against the approved spec**

```powershell
Set-Location $repo
git diff --stat 82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb..HEAD
git diff --name-status 82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb..HEAD
git log --oneline 82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb..HEAD
```

Confirm every changed file is identity configuration, a guard/test, automation cleanup, or transformation documentation.

- [ ] **Step 2: Recheck prohibited additions**

```powershell
Set-Location $repo
git ls-files | rg "google-services\.json|GoogleService-Info\.plist|dart_defines.*local|\.env"
git diff 82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb..HEAD -- LICENSE budget/lib/database budget/lib/pages budget/lib/models
```

Expected: no tracked external-service secrets/configs and no prohibited financial/database/licence changes.

- [ ] **Step 3: Produce the owner report and stop**

Report all 21 requested items:

1. inherited Android identifiers;
2. inherited iOS identifiers;
3. inherited Web/PWA identifiers;
4. files changed;
5. final Android identity architecture;
6. final iOS identity architecture;
7. final Web/PWA identity architecture;
8. implemented now;
9. reserved/documented only;
10. Firebase/OAuth implications;
11. required external registrations;
12. remaining Cashew-facing identifiers;
13. tests added/changed;
14. full test result;
15. Flutter analysis result;
16. Web Development build result;
17. Drift v47 confirmation;
18. financial logic untouched confirmation;
19. branch;
20. commit hash;
21. owner actions.

Then stop. Do not begin Figma, redesign, new financial features, AI, Production/Staging Firebase, or app-store registration.
