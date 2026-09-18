# Phase 2 — OLA Edge Finance Brand Foundation

Implementation date: 2026-09-18

Approved working product name: **OLA Edge Finance**

## Outcome

Phase 2 establishes a reversible user-facing product identity without changing financial behavior, data storage, original service infrastructure, or licensing provenance. The name is centralized in a typed Flutter configuration and a machine-readable manifest. Android, iOS, and web display metadata now use OLA Edge Finance.

This is a brand foundation, not a complete visual rebrand. Existing icons, colors, fonts, launch imagery, and screen design remain unchanged until original assets and visual direction are approved.

## Identity sources

| Path | Responsibility |
|---|---|
| `budget/brand/brand_manifest.json` | Canonical non-secret public product identity and compatibility policy |
| `budget/lib/brand/brand_identity.dart` | Immutable `BrandIdentity` type and compile-time `appBrand` value |
| `budget/lib/struct/languageMap.dart` | Compatibility `globalAppName` getter forwarding to `appBrand.productName` |
| `budget/test/brand/brand_identity_test.dart` | Typed identity regression test |
| `budget/test/brand/brand_manifest_contract_test.dart` | Platform parity, protected identifier, and Cashew-reference audit |

The JSON and Dart declarations intentionally duplicate compile-time values. Tests enforce exact agreement without adding code generation, runtime configuration loading, or new dependencies.

## User-facing changes

- Flutter `MaterialApp.title` now reads `appBrand.productName`.
- Existing UI that reads `globalAppName` now receives OLA Edge Finance through the compatibility getter.
- Android application label is OLA Edge Finance.
- iOS display name and camera/photo permission descriptions use OLA Edge Finance.
- Web/PWA application name, short name, Apple web-app title, document title, and social title metadata use OLA Edge Finance.
- Literal Latin `Cashew` references in current non-historical translation rows were changed to OLA Edge Finance in the canonical CSV and generated JSON.
- The Android notification-template explanation now names OLA Edge Finance.

## Preserved compatibility and infrastructure

Automated tests assert that this phase did not change:

- Android application ID and manifest package;
- iOS application bundle ID;
- Firebase project configuration;
- OAuth identities and URL schemes;
- Cashew app-link domains;
- in-app purchase product IDs and subscription URLs;
- Google Drive backup/sync identity and attachment-folder name;
- Drift schema version, migration implementation, or exported schemas;
- backup formats and the historical Cashew backup warning;
- upstream source URLs, GPL license, copyright, and attribution.

No dependency, database, migration, Firebase, OAuth, IAP, deep-link, icon, color, or financial-logic file was changed.

## Remaining Cashew references

The automated audit allows only narrow compatibility/provenance contexts:

- GPL/legal notices and upstream-source references;
- root upstream README and transformation documentation;
- historical changelog text;
- `CashewAppMain`, retained as an internal widget key;
- internal `CashewProBanner` Dart symbol names whose visible text already comes from `appBrand`;
- original app-link domains and source URLs;
- protected IAP identifiers;
- Google Drive attachment-folder identity;
- translated `import-warning-description` text identifying historical Cashew backup files.

A new literal `Cashew` occurrence outside the test allowlist fails the brand contract test with its path and line.

## Localization limitation

The source translation catalog contains historical translations where the Cashew brand was translated as the cashew nut, paraphrased as “the app,” or misspelled. This phase replaced exact Latin `Cashew` tokens outside the backup warning but did not reinterpret non-Latin words or translator intent. A professional localization pass is required after final brand voice and supported markets are approved. The canonical backup-warning row was preserved byte-for-byte to protect compatibility messaging.

## Verification evidence

Verified on Flutter 3.19.6 and Dart 3.3.4:

| Command | Result |
|---|---|
| `flutter test test/brand --no-pub` | PASS — 7 brand/compatibility tests |
| `flutter test --no-pub` | BASELINE FAIL — brand tests pass; the pre-existing counter-template test still fails at `test/widget_test.dart:18` |
| `flutter analyze --no-pub` | FAIL — 236 findings in the current full scan, including the existing missing-lint configuration and historical code diagnostics; no finding points to the new brand module/tests |
| `flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --no-pub` | PASS — release web compilation completed in 424.9 seconds |

The initially annotated compatibility getter produced 10 additional analyzer infos at retained callers. Systematic verification isolated the annotation as the cause; removing only the annotation reduced the full scan from 246 to 236 findings while preserving the getter and behavior. Static analysis is not green and remains Phase 0 debt.

## Security and licensing

- The brand manifest contains public naming/provenance values only.
- No credential, client secret, service account, signing key, or private endpoint was added.
- The GPL-3.0-or-later license and James Kokoska/Cashew provenance remain intact.
- OLA Edge Finance remains a working name pending final trademark and legal approval.
- Corresponding Source and app-store GPL compatibility remain release gates documented in `06_LICENSE_REVIEW.md`.

## Deferred decisions

- Legal publisher/entity and final trademark approval.
- Permanent Android/iOS identifiers and owned web/app-link domains.
- New Firebase/Google environments and production service ownership.
- Privacy, terms, support, and email properties.
- Original logo, icon, splash/launch imagery, colors, typography, and design tokens.
- Store listings, monetization names, and purchase identifiers.
- Formal migration policy for old Cashew Drive backups and shared/cloud data.
- Professional translation review and market-specific brand localization.

These items require separate approval and compatibility plans. They must not be inferred from the working name or changed through broad search-and-replace.
