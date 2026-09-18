# Cashew Codebase Audit

Audit date: 2026-09-18

Repository revision: `9cfbe50c16d95429891d44faf5f2c77a3abdb93b` (`main`)

Application version: `5.4.3+416`

## Scope and method

This audit uses the checked-out source as the source of truth. It covers the repository root and the Flutter application in `budget/`, including platform projects, generated Drift schemas, bundled packages, assets, tests, cloud integrations, and release metadata. No application code, dependencies, database schema, branding, or service configuration was changed.

The repository contains about 836 tracked files. The largest areas are `budget/assets`, `budget/lib`, the Android and iOS projects, bundled packages, Drift schema snapshots, and web assets.

## Repository map

| Path | Responsibility |
|---|---|
| `README.md`, `LICENSE` | Project overview and GPL-3.0-or-later licensing |
| `budget/lib/main.dart` | Bootstrap, Firebase initialization, localization, database, notifications, and application shell |
| `budget/lib/pages/` | Screen-level presentation and substantial feature/business logic |
| `budget/lib/widgets/` | Reusable controls, feature widgets, charts, dialogs, and navigation |
| `budget/lib/database/` | Drift tables, DAOs/queries, generated code, platform connection, and migrations |
| `budget/lib/struct/` | Shared models, parsing, import, sync, notification, and feature helpers |
| `budget/lib/settings/` | Settings pages and application preferences |
| `budget/lib/firebase_options.dart` | Generated Firebase platform configuration for the original project |
| `budget/drift_schemas/` | Exported Drift schemas for versions 33 through 46 |
| `budget/assets/` | Translations, fonts, icons, category assets, images, and static data |
| `budget/android/`, `budget/ios/`, `budget/web/` | Platform packaging and integrations |
| `budget/packages/` | Locally bundled/modified Flutter packages |
| `budget/test/` | One stale generated widget test |
| `promotional/` | Existing store/promotional graphics tied to Cashew |

## Application startup

`budget/lib/main.dart` performs the following sequence:

1. Initializes Flutter bindings and Firebase using `DefaultFirebaseOptions`.
2. Initializes EasyLocalization, SharedPreferences, currencies/languages, timezone data, notifications, icon data, and display refresh behavior.
3. Opens the Drift database through `constructDb('db')`.
4. Builds `MaterialApp` with Cashew themes and the nested navigation framework.
5. Starts notification scheduling, quick actions, store/IAP setup, backup reminders, recurring/upcoming transaction processing, orphan cleanup, and automatic sync watchers.

Initialization is functional but highly centralized. Several global singletons, `GlobalKey` instances, `ValueNotifier`s, and the dynamic `appStateSettings` map are shared across features.

## Navigation and screens

Navigation is imperative rather than declarative. `InitialPageRouteNavigator` selects onboarding or the main app from `appStateSettings["hasOnboarded"]`. The primary lazy/fading indexed stack contains Home, Transactions, Budgets, and More/Settings. Additional numeric page indexes cover accounts, account details, recurring and upcoming transactions, categories, goals, analytics, notifications, and editors. Detail flows generally use `Navigator.push` through the shared `pushRoute` helper.

The same navigation framework provides a mobile bottom bar and a responsive sidebar. Numeric indexes and global navigation keys create coupling that should be reduced incrementally, but they are not a reason to rewrite the app.

## State and business logic

The application uses a hybrid approach:

- Provider supplies streams for all wallets and the selected wallet.
- Drift streams and `StreamBuilder` provide most reactive financial data.
- Widgets and pages use substantial local `setState` logic.
- SharedPreferences and the `AppSettings` table back a global dynamic settings map.
- Business rules are distributed among pages, widgets, database methods, and helpers under `struct/`.

There is no clean repository/domain/application-service boundary. This is the main maintainability constraint for a large redesign, but the proven feature code can be retained while seams are introduced around it.

## Data and cloud summary

The local source of truth is Drift over SQLite on Android/iOS and IndexedDB-backed Drift storage on web. Schema version 46 contains ten tables covering wallets, transactions, categories, budgets, goals, settings, scanner templates, and sync tombstones. Migration history is preserved in code and in exported schema snapshots from versions 33–46.

Firebase provides authentication and Firestore-backed shared budgets. Google APIs provide sign-in, Drive backup/sync, and optional Gmail transaction scanning. Local notifications, Android notification-listener access, biometrics, home widgets, quick actions, app links, IAP, and store review are platform integrations.

## Configuration observations

- Android application ID: `com.budget.tracker_app`.
- iOS application bundle ID: `com.budget.tracker-app`.
- The web app, Firebase project, OAuth clients, deep links, store links, Drive folder name, and purchase products are tied to Cashew infrastructure.
- Firebase configuration is checked in for the public client applications. Values are not repeated in these documents.
- No Firestore security-rules or index definitions were found in the repository.
- No Firebase Analytics, Crashlytics, Sentry, or Firebase Cloud Messaging dependency was found.
- Notifications are local/scheduled; Android also supports notification-listener parsing.

## Platform configuration

### Android

The Android project uses application ID `com.budget.tracker_app`, minimum SDK 23, compile/target SDK 34, Android Gradle Plugin 7.3.1, Gradle 7.5, Kotlin 1.9.0, and Java 8/desugaring configuration. The manifest includes billing, biometric, notification, boot/scheduling, storage/media, deep-link, home-widget, and notification-listener integration. The label and link host are Cashew-specific. Kotlin source files live in an older directory structure while declaring the current application package, which should be normalized only during the controlled identifier migration.

### iOS

The iOS bundle identifier is `com.budget.tracker-app`. The project contains Cashew display/permission text, Google OAuth URL-scheme configuration, push entitlement, and the associated domain for the Cashew web host. The test target retains an older bundle naming pattern. Signing, capabilities, Google sign-in, links, notifications, biometrics, camera/photo access, IAP, and widgets require verification on macOS/Xcode.

### Web/PWA

The web target contains a PWA manifest, icons, Cashew title/description/social metadata, theme color, Firebase bootstrap values, Google sign-in client configuration, and SQL/WASM support assets. Firebase Hosting configuration and Cashew-hosted URLs are part of the original infrastructure. The web release compiled and served during the audit.

## Localization and visual system

EasyLocalization loads JSON translation assets with English fallback and a declared supported-locale map. Translation assets include a few files not exposed by that map, so locale coverage should be reconciled rather than inferred from file count. The theme system supports light/dark behavior, system/Material You accent colors, user-selected accents, grayscale options, chart colors, and configurable bundled fonts. These mechanics are reusable; font redistribution rights and all brand-facing tokens require review.

## Testing and maintainability

Testing coverage is insufficient for financial software. The only top-level Flutter test is an unmaintained counter-template test. Some bundled packages have their own tests, and iOS includes a template test target, but core database migrations, calculations, imports, sync conflict behavior, and transaction workflows lack an application-level regression suite.

Several very large files concentrate risk, including the Drift database implementation, add/edit transaction flow, migration definitions, changelog, wallet details, and generated database code. Future work should extract tested seams only when touching a feature; a repository-wide refactor would add unnecessary risk.

## Audit conclusion

Cashew is a substantial and reusable product foundation with mature personal-finance behavior, broad platform integrations, and an evolved migration history. It is not yet a clean product-development baseline because static analysis and tests are not green, cloud configuration is inseparable from the original deployment, and business logic is coupled to presentation and global state. These issues are tractable through staged separation rather than a rewrite.
