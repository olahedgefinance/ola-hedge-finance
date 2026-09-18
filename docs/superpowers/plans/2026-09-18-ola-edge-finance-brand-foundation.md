# OLA Edge Finance Brand Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish OLA Edge Finance as the reversible user-facing product identity while mechanically protecting Cashew infrastructure, data compatibility, and GPL provenance.

**Architecture:** A checked-in JSON manifest is the canonical public brand record, while an immutable Dart constant provides compile-time Flutter access. Platform-native metadata duplicates the required display values, and focused contract tests enforce parity, protected identifiers, and a narrow allowlist for remaining Cashew references.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, `flutter_test`, JSON, Android XML/Gradle, iOS plist/Xcode project metadata, HTML/PWA manifest.

**Spec:** `docs/superpowers/specs/2026-09-18-ola-edge-finance-brand-foundation-design.md`

## Global Constraints

- The product name is exactly `OLA Edge Finance`.
- Do not change icons, colors, fonts, screens, financial behavior, package dependencies, database schema, migrations, or data formats.
- Preserve Android/iOS identifiers, Firebase/OAuth configuration, app-link domains, IAP IDs, Google Drive backup/attachment identity, source URLs, GPL notices, and historical backup wording.
- The manifest must contain no credentials, signing material, secrets, or private endpoints.
- Flutter/Dart remain pinned to the verified 3.19.6/3.3.4 baseline for validation.
- Every implementation task follows red-green-refactor and ends with a focused commit.

---

### Task 1: Canonical manifest and typed Flutter identity

**Files:**
- Create: `budget/brand/brand_manifest.json`
- Create: `budget/lib/brand/brand_identity.dart`
- Create: `budget/test/brand/brand_identity_test.dart`
- Modify: `budget/lib/struct/languageMap.dart:8`
- Modify: `budget/lib/main.dart:116`

**Interfaces:**
- Produces: `const BrandIdentity appBrand` with `productName`, `shortName`, and `description` string fields.
- Produces: compatibility getter `String get globalAppName` returning `appBrand.productName`.
- Consumes: no runtime services or assets.

- [ ] **Step 1: Write the failing identity test**

```dart
import 'package:budget/brand/brand_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OLA Edge Finance identity is stable', () {
    expect(appBrand.productName, 'OLA Edge Finance');
    expect(appBrand.shortName, 'OLA Edge Finance');
    expect(
      appBrand.description,
      'A budget and financial tracking application designed for you',
    );
  });
}
```

- [ ] **Step 2: Run the focused test and verify red**

Run from `budget/`:

```powershell
flutter test test/brand/brand_identity_test.dart --no-pub
```

Expected: FAIL because `package:budget/brand/brand_identity.dart` does not exist.

- [ ] **Step 3: Create the manifest and minimal typed identity**

Create the exact JSON object specified in the approved design. Implement:

```dart
class BrandIdentity {
  const BrandIdentity({
    required this.productName,
    required this.shortName,
    required this.description,
  });

  final String productName;
  final String shortName;
  final String description;
}

const BrandIdentity appBrand = BrandIdentity(
  productName: 'OLA Edge Finance',
  shortName: 'OLA Edge Finance',
  description: 'A budget and financial tracking application designed for you',
);
```

Change `languageMap.dart` from a mutable literal to:

```dart
@Deprecated('Use appBrand.productName')
String get globalAppName => appBrand.productName;
```

Import the brand module and change only the user-facing `MaterialApp.title` in `main.dart` to `appBrand.productName`. Preserve `ValueKey('CashewAppMain')` as an internal compatibility key.

- [ ] **Step 4: Run identity test and analyzer for changed Dart files**

```powershell
flutter test test/brand/brand_identity_test.dart --no-pub
flutter analyze lib/brand/brand_identity.dart lib/struct/languageMap.dart lib/main.dart --no-pub
```

Expected test: PASS. Analyzer may retain the already documented missing `flutter_lints` include; there must be no new Dart error from these files.

- [ ] **Step 5: Commit the identity boundary**

```powershell
git add budget/brand/brand_manifest.json budget/lib/brand/brand_identity.dart budget/lib/struct/languageMap.dart budget/lib/main.dart budget/test/brand/brand_identity_test.dart
git commit -m "feat: add OLA Edge Finance identity boundary"
```

---

### Task 2: Platform display metadata contract

**Files:**
- Create: `budget/test/brand/brand_manifest_contract_test.dart`
- Modify: `budget/android/app/src/main/AndroidManifest.xml:33`
- Modify: `budget/ios/Runner/Info.plist:11-22`
- Modify: `budget/ios/Runner.xcodeproj/project.pbxproj` display-name settings only
- Modify: `budget/web/manifest.json:2-6`
- Modify: `budget/web/index.html:20-52`

**Interfaces:**
- Consumes: `brand/brand_manifest.json` and `appBrand` from Task 1.
- Produces: platform metadata equality contract reusable by the brand audit.

- [ ] **Step 1: Write failing manifest/platform tests**

The test loads the manifest with `File('brand/brand_manifest.json')`, asserts schema version/name/description/license values, then reads platform files and expects:

```dart
expect(androidManifest, contains('android:label="OLA Edge Finance"'));
expect(iosPlist, contains('<string>OLA Edge Finance</string>'));
expect(
  iosPlist,
  contains('OLA Edge Finance uses photos to attach to a transaction entry'),
);
expect(webManifest['name'], 'OLA Edge Finance');
expect(webManifest['short_name'], 'OLA Edge Finance');
expect(webIndex, contains('<title>OLA Edge Finance</title>'));
expect(webIndex, contains('content="OLA Edge Finance"'));
```

Also compare manifest values to `appBrand` so duplicate compile-time declarations cannot drift.

- [ ] **Step 2: Run the contract test and verify red**

```powershell
flutter test test/brand/brand_manifest_contract_test.dart --no-pub
```

Expected: FAIL on Cashew platform display metadata.

- [ ] **Step 3: Apply only reversible metadata edits**

Change Android label; all active iOS `CFBundleDisplayName` declarations; iOS display name and photo/camera descriptions; web manifest name/short name/description; HTML title, Apple mobile web title, title metadata, and Open Graph/Twitter title/description. Do not edit web URLs, Firebase bootstrap values, Google client IDs, icons, theme colors, package IDs, bundle IDs, or entitlements.

- [ ] **Step 4: Run the contract and identity tests**

```powershell
flutter test test/brand/brand_identity_test.dart test/brand/brand_manifest_contract_test.dart --no-pub
```

Expected: PASS.

- [ ] **Step 5: Commit platform branding**

```powershell
git add budget/android/app/src/main/AndroidManifest.xml budget/ios/Runner/Info.plist budget/ios/Runner.xcodeproj/project.pbxproj budget/web/manifest.json budget/web/index.html budget/test/brand/brand_manifest_contract_test.dart
git commit -m "feat: apply OLA Edge Finance display metadata"
```

---

### Task 3: Brand-reference and protected-identifier audit

**Files:**
- Modify: `budget/test/brand/brand_manifest_contract_test.dart`
- Modify: `budget/assets/translations/translations.csv`
- Regenerate: `budget/assets/translations/generated/*.json`
- Modify: `budget/lib/pages/autoTransactionsPageEmail.dart:232`

**Interfaces:**
- Consumes: canonical manifest and repository files.
- Produces: a path-aware audit that reports accidental `Cashew` branding and protected identifier drift.

- [ ] **Step 1: Add failing protected-identifier assertions**

Assert exact preserved public identifiers without copying credentials:

```dart
expect(androidGradle, contains('applicationId "com.budget.tracker_app"'));
expect(androidManifest, contains('package="com.budget.tracker_app"'));
expect(androidManifest, contains('android:host="cashewapp.web.app"'));
expect(iosProject, contains('PRODUCT_BUNDLE_IDENTIFIER = "com.budget.tracker-app"'));
expect(iosEntitlements, contains('applinks:cashewapp.web.app'));
expect(firebaseOptions, contains("projectId: 'budget-app-flutter'"));
expect(databaseSource, contains('schemaVersionGlobal = 46'));
expect(premiumSource, contains('cashew.pro.monthly'));
expect(uploadSource, contains('String folderName = "Cashew"'));
```

Add license/source assertions for GPL-3.0-or-later provenance and the upstream repository URL.

- [ ] **Step 2: Add a failing path-aware Cashew reference audit**

Scan current first-party display surfaces and translation sources. Permit only:

- `CashewAppMain` in `lib/main.dart`;
- `cashewapp.web.app` URLs in Android/web/current source;
- upstream `github.com/jameskokoska/Cashew` links;
- `Cashew` in the `import-warning-description` CSV/generated JSON entry;
- `Cashew` Drive folder identity in `lib/struct/uploadAttachment.dart`;
- internal `CashewProBanner` symbol names and protected IAP IDs;
- historical `lib/widgets/showChangelog.dart` text.

Every other literal `Cashew` match in current app code, platform display metadata, or non-historical translation rows fails with file and line. Do not scan root upstream README, `LICENSE`, audit/spec/plan docs, build output, or generated plugin registrants as current OLA UI.

- [ ] **Step 3: Run the audit and verify red**

```powershell
flutter test test/brand/brand_manifest_contract_test.dart --no-pub
```

Expected: FAIL on current translation rows and the notification-template explanation.

- [ ] **Step 4: Make the smallest copy changes**

Change the notification-template sentence to name OLA Edge Finance. In the canonical translation CSV, mechanically replace literal `Cashew` with `OLA Edge Finance` only in non-historical rows; leave the entire `import-warning-description` row byte-for-byte unchanged. Run the existing `generate-translations.py` generator so JSON matches the canonical CSV. Do not translate, replace, or reinterpret non-Latin historical brand terms in this phase.

- [ ] **Step 5: Run focused tests and verify protected files**

```powershell
flutter test test/brand/brand_identity_test.dart test/brand/brand_manifest_contract_test.dart --no-pub
git diff -- budget/lib/firebase_options.dart budget/android/app/google-services.json budget/ios/Runner/GoogleService-Info.plist budget/drift_schemas budget/lib/database
```

Expected: tests PASS; protected-file diff is empty.

- [ ] **Step 6: Commit the automated guardrails**

```powershell
git add budget/test/brand/brand_manifest_contract_test.dart budget/assets/translations/translations.csv budget/assets/translations/generated budget/lib/pages/autoTransactionsPageEmail.dart
git commit -m "test: guard brand and compatibility boundaries"
```

---

### Task 4: Phase 2 record and full verification

**Files:**
- Create: `docs/transformation/12_PHASE_2_BRAND_FOUNDATION.md`

**Interfaces:**
- Consumes: implementation and fresh verification evidence from Tasks 1–3.
- Produces: auditable changed/preserved/deferred record for the next product phase.

- [ ] **Step 1: Write the Phase 2 record**

Document the exact product name, manifest/config paths, platform display changes, test commands, preserved identifiers, allowed remaining Cashew references with reasons, localized-copy limitation, and deferred logo/color/domain/legal/infrastructure decisions. State that the working name still requires final trademark/legal clearance.

- [ ] **Step 2: Run focused and baseline verification**

From `budget/`, using the task-local Flutter 3.19.6 environment:

```powershell
flutter test test/brand --no-pub
flutter test --no-pub
flutter analyze --no-pub
flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --no-pub
```

Expected:

- brand tests: PASS;
- complete tests: the pre-existing counter-template test may still fail and must be reported without being changed;
- analysis: the pre-existing missing `flutter_lints` include may remain and must have no new implementation error;
- release web build: PASS.

- [ ] **Step 3: Verify scope and secret safety**

```powershell
git diff 471e739 --check
git diff 471e739 --name-only
rg -n --pcre2 "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|client_secret\\s*[:=]|private_key\\s*[:=]" budget/brand budget/lib/brand budget/test/brand docs/transformation/12_PHASE_2_BRAND_FOUNDATION.md
```

Expected: no whitespace errors, only approved files, and no sensitive-pattern matches.

- [ ] **Step 4: Commit documentation**

```powershell
git add docs/transformation/12_PHASE_2_BRAND_FOUNDATION.md
git commit -m "docs: record OLA Edge Finance brand foundation"
```

- [ ] **Step 5: Final repository check**

```powershell
git status --short --branch
git log -6 --oneline
```

Expected: clean worktree, branch ahead only by the audit/spec/plan/Phase 2 commits, no push performed.
