# OLA Edge Finance Brand Foundation Design

Date: 2026-09-18

Status: Approved design captured for implementation review

## Purpose

Establish **OLA Edge Finance** as the approved working product name without disturbing Cashew's proven financial behavior, database compatibility, original infrastructure, or GPL provenance. This phase creates a single auditable product-identity boundary and applies it only to reversible user-facing metadata and copy.

## Scope

### In scope

- A machine-readable brand manifest committed with the application.
- A typed Dart brand configuration consumed by Flutter UI code.
- User-facing product-name changes in:
  - Flutter application title and global display-name consumers;
  - Android application label;
  - iOS display name and camera/photo permission descriptions;
  - web/PWA title, application name, and generic product description metadata.
- Automated checks that:
  - verify platform metadata matches the brand manifest;
  - detect accidental user-facing `Cashew` references;
  - explicitly allow required legal, upstream-source, historical, infrastructure, and backup-compatibility references;
  - prevent protected identifiers from changing during this phase.
- Documentation of deferred brand and infrastructure decisions.

### Out of scope

- Package or bundle identifier changes.
- Firebase projects, generated Firebase configuration, OAuth clients, Google service files, or authentication scopes.
- Deep-link/app-link domains and association files.
- In-app purchase identifiers, entitlement behavior, pricing, or store listings.
- Google Drive app-data identity, backup filenames/formats, attachment-folder identity, or restore compatibility wording.
- Database schema, migrations, table data, settings keys, or sync behavior.
- Source repository URLs, GPL license text, attribution, copyright, upstream history, or third-party notices.
- Icons, logos, launch imagery, color system, fonts, or screen redesign.
- Historical changelog entries and old release documentation.
- Broad dependency upgrades or architectural refactors.

## Architecture

### Canonical manifest

Create `budget/brand/brand_manifest.json` as the canonical non-secret identity record. It has this structure:

```json
{
  "schemaVersion": 1,
  "brandKey": "ola-edge-finance",
  "productName": "OLA Edge Finance",
  "shortName": "OLA Edge Finance",
  "description": "A budget and financial tracking application designed for you",
  "license": {
    "spdx": "GPL-3.0-or-later",
    "upstreamProduct": "Cashew",
    "upstreamRepository": "https://github.com/jameskokoska/Cashew"
  },
  "preservedCompatibility": [
    "application-identifiers",
    "firebase-and-oauth",
    "deep-links",
    "in-app-purchases",
    "drive-backup-identity",
    "database-and-migrations",
    "historical-backup-wording",
    "source-and-license-references"
  ]
}
```

The manifest contains no credentials, signing material, private endpoints, or environment secrets.

### Typed Flutter configuration

Create `budget/lib/brand/brand_identity.dart` with an immutable `BrandIdentity` value type and a single `appBrand` constant. Required fields are `productName`, `shortName`, and `description`. `globalAppName` remains as a deprecated compatibility getter during this phase so existing widgets do not require a repository-wide refactor; it returns `appBrand.productName` and is removed only after consumers migrate incrementally.

The Dart constant and JSON manifest intentionally duplicate compile-time values. A brand-contract test fails if they diverge. This avoids introducing code generation, build-runner changes, or runtime asset loading for the application title.

### Platform metadata

Static Android, iOS, and web metadata cannot import Dart values. They therefore retain platform-native declarations, with automated contract tests enforcing exact equality to the manifest:

- Android `android:label`: `OLA Edge Finance`.
- iOS `CFBundleDisplayName`: `OLA Edge Finance` in plist/project build settings, and permission descriptions use the same product name.
- Web manifest `name` and `short_name`: `OLA Edge Finance`.
- Web document, Open Graph, and Twitter titles: `OLA Edge Finance`.
- Web description preserves the existing generic product description recorded in the manifest.

No domain, client ID, Firebase value, or icon path changes with these edits.

## Brand-reference policy

The automated audit classifies remaining `Cashew` references by purpose rather than treating all matches as defects.

### Allowed references

- `LICENSE`, copyright, GPL notices, attribution, and upstream repository links.
- Root README content describing the upstream project.
- Historical changelog/release text.
- Generated translation strings whose wording identifies the historical Cashew backup format.
- Google Drive folder/backup compatibility values retained by this phase.
- Package IDs, domains, Firebase/OAuth configuration, IAP product IDs, and source paths retained by this phase.
- Audit/transformation documentation explaining provenance or migration.

### Disallowed references

- Current Flutter application title or display-name constant.
- Android application label.
- iOS display name and current camera/photo permission copy.
- Current web/PWA name and title metadata.
- New OLA Edge Finance-owned UI copy introduced during or after this phase.

Allowed references are recorded as narrow file/path rules with reasons. The audit fails on a new match outside those rules. Allowlist rules must not suppress entire first-party source trees when a specific file or pattern is sufficient.

## Protected compatibility contract

The automated checks snapshot and verify that Phase 2 does not change:

- Android application ID and manifest package;
- iOS product bundle identifier;
- Firebase project identifiers and generated configuration files;
- OAuth client identifiers and URL schemes;
- Cashew app-link domains;
- IAP product IDs and subscription-management URLs;
- Drive backup/sync prefixes and attachment-folder identity;
- Drift schema version, migration files, and exported schema snapshots;
- upstream source and GPL license URLs.

The check may contain public identifiers needed for comparison but must never copy private credentials. Changes to these values require a separately approved infrastructure or compatibility migration.

## Files and responsibilities

| File | Responsibility |
|---|---|
| `budget/brand/brand_manifest.json` | Canonical machine-readable public brand record |
| `budget/lib/brand/brand_identity.dart` | Typed Flutter brand identity and `appBrand` constant |
| `budget/lib/struct/languageMap.dart` | Compatibility getter forwarding `globalAppName` to `appBrand.productName` |
| `budget/lib/main.dart` | Consume `appBrand.productName` for the user-facing application title; preserve internal compatibility keys |
| Android manifest | Set display label only |
| iOS plist/project | Set display name and permission copy only |
| `budget/web/manifest.json`, `budget/web/index.html` | Set PWA/document/social product name and description only |
| `budget/test/brand/brand_identity_test.dart` | Verify typed values and compatibility getter |
| `budget/test/brand/brand_manifest_contract_test.dart` | Verify manifest/platform agreement, protected identifiers, and allowed reference policy |
| `docs/transformation/12_PHASE_2_BRAND_FOUNDATION.md` | Record changed, preserved, deferred, and verification results |

## Test strategy

1. Write a failing unit test for `BrandIdentity` and the `appBrand` values.
2. Write a failing manifest contract test that reads `brand_manifest.json` and asserts exact typed/platform values.
3. Add protected-identifier assertions before editing platform metadata.
4. Add a path-aware Cashew-reference audit with the narrow allowlist described above.
5. Make the minimal identity and metadata edits until tests pass.
6. Run focused brand tests, the complete Flutter test suite, Flutter analysis, and a release web build.
7. Treat unrelated baseline test/analysis failures exactly as documented; do not broaden scope to repair them in this phase.

## Error and safety behavior

- Missing or malformed manifest data fails tests and CI; the app does not parse the manifest at runtime.
- A platform name mismatch fails with the file and expected value.
- A new disallowed `Cashew` match fails with its path and line.
- A protected identifier change fails with the protected field name.
- No automated replacement is allowed in license, migration, backup, Firebase, OAuth, IAP, or historical files.

## Acceptance criteria

- The app's current user-facing display name is exactly `OLA Edge Finance` on Flutter, Android, iOS, and web metadata surfaces.
- Product identity is available through typed `appBrand` configuration.
- `brand_manifest.json` is the canonical public identity record and contains no secrets.
- Brand contract tests pass and distinguish required Cashew references from accidental current branding.
- Protected infrastructure/data identifiers are unchanged.
- Icons, colors, database schema, dependencies, and financial behavior are unchanged.
- GPL license and upstream attribution remain intact and discoverable.
- The release web build still succeeds on the established Flutter 3.19.6/Dart 3.3.4 baseline.

## Deferred decisions

- Legal publisher/entity name and target jurisdictions.
- Trademark clearance and permanent store-facing approval of `OLA Edge Finance`.
- Permanent Android/iOS identifiers and owned web/app-link domains.
- Firebase/Google environments and production infrastructure.
- Support, privacy, terms, and email URLs owned by the new publisher.
- Original logo/icon/launch assets, color tokens, typography, and visual identity.
- Monetization product names and identifiers.
- Whether and how old Cashew backups/Drive data migrate into separately identified production apps.

These decisions are not silently defaulted. Each requires an approved later change set with its own compatibility and release plan.
