# Brand Separation Audit

This inventory distinguishes visual/content branding from infrastructure identity and licensing. Changing a logo is low risk; changing package IDs, OAuth clients, shared-data backends, or legal notices is not.

## BRANDING — expected to change

| Area | Cashew coupling found | Change direction |
|---|---|---|
| Product name | `Cashew`, `globalAppName`, page titles, localization strings, about/premium copy | Define the new product name and controlled naming tokens |
| Logos and icons | App launcher icons, web icons, in-app imagery, promotional assets | Produce original assets and regenerate every platform size |
| Splash/launch experience | Android/iOS/web launch assets and color metadata | Rebuild from approved design tokens |
| Colors and themes | Cashew color schemes, system-accent options, chart colors | Retain theme mechanics; replace brand tokens and validate contrast |
| Typography | Bundled Avenir, DM Sans, Metropolis, Roboto Condensed, Inconsolata, Inter fallback | Confirm font redistribution licenses before selecting the new type system |
| Web metadata | Name, short name, description, title, Open Graph/Twitter content, theme color | Replace with the new product and canonical domain |
| Store/promotional media | Screenshots, banners, icons, and marketing images under `promotional/` | Replace completely; do not reuse Cashew trade dress |
| In-app terminology | CashewPro, donation/support text, Drive folder name, export/backup labels | Rename after data compatibility implications are documented |
| Help/support content | Cashew FAQ, privacy, support, donation, GitHub, and developer-email links | Replace with owned, published support/legal properties |
| Rating/store links | Cashew store package/listing destinations | Replace after new listings exist |

## INFRASTRUCTURE — replace or configure carefully

| Area | Existing identity/configuration | Required migration control |
|---|---|---|
| Android | Application ID `com.budget.tracker_app`, manifest label, deep-link host, widget/service metadata | Choose a permanent reverse-DNS ID; update source paths, manifests, Firebase app, store listing, signing, links, and tests together |
| iOS | Bundle ID `com.budget.tracker-app`, display name, URL schemes, associated domain, usage strings | Register a new App ID and capabilities; update entitlements, OAuth scheme, signing, and tests |
| Web/PWA | Cashew manifest/title/social metadata, icons, hosted domain, inline client configuration | Create an owned domain/hosting target and environment-specific configuration |
| Firebase | Original Firebase project/apps and hosting aliases in generated/config files | Create development/staging/production projects; regenerate configs; do not copy server-side rules blindly |
| OAuth | Original Google client IDs, redirect schemes, sign-in scopes | Create new consent screen and clients; minimize and verify Gmail/Drive scopes |
| Firestore | Original shared-budget collections and implicit server rules | Design rules/indexes, tenancy, deletion, abuse, and migration before enabling sharing |
| Deep/app links | `cashewapp.web.app` and platform intent/associated-domain configuration | Use a verified owned domain and publish association files |
| Purchases | Cashew product IDs, entitlement and paywall copy | Define new products, pricing, restore behavior, and receipt validation |
| Store identity | Existing Android/iOS listing identifiers and review URLs | Create separate listings; do not attempt to inherit the original identity |
| Google Drive/Gmail | App identity, scopes, consent text, backup naming/folders | Re-authorize under the new OAuth project; treat old backups as an explicit compatibility decision |
| Signing | Android keystore references and Apple signing/capability settings | Use new protected credentials outside version control and CI secret storage |
| Privacy/security | Permission descriptions, notification listener, Gmail access, biometrics, backups | Produce a data map, consent copy, retention policy, and threat model before release |

Public client configuration files are present at `budget/lib/firebase_options.dart`, `budget/android/app/google-services.json`, additional historical Android Google-services files, `budget/.firebaserc`, `budget/firebase.json`, and `budget/web/index.html`. Their values are deliberately not reproduced here. Historical/dev configuration files should be reviewed and retired only after ownership and usage are established.

## LEGAL — retain and understand

- Root `LICENSE` identifies Cashew as GPL-3.0-or-later and names James Kokoska as copyright holder.
- Copyright, license, source-availability, modification, and no-warranty notices cannot be replaced by brand copy.
- Third-party package, font, icon, and asset licenses must remain discoverable and be re-audited before reuse.
- The current in-app license/about wording appears to include MIT-style warranty language and should be reconciled with the actual GPL notice by counsel; do not simply delete it.
- Removing Cashew names from product branding does not erase provenance or GPL obligations.

## Search locations for later implementation

- Flutter code and localized content: `budget/lib`, `budget/assets/translations`.
- App metadata: `budget/pubspec.yaml`, Android manifests/Gradle, iOS project/plists/entitlements, and `budget/web`.
- Images/fonts/icons: `budget/assets`, platform asset catalogs, launcher resources, and `promotional/`.
- Cloud/store values: Firebase generated files, Google-services files, web bootstrap configuration, OAuth URL schemes, IAP constants, and external-link helpers.
- Legal/support: root `LICENSE`, README, About/licenses UI, privacy/FAQ/support URLs, and third-party package metadata.

## Safe order of separation

1. Approve the new legal entity, product name, owned domains, and permanent package/bundle IDs.
2. Inventory third-party asset/font rights and preserve GPL notices.
3. Create isolated development cloud/store identities with no production data.
4. Introduce non-secret environment selection and configuration validation.
5. Replace names, URLs, visual tokens, and assets through a reviewed manifest.
6. Test upgrade/backup compatibility and deep-link/auth flows on every platform.
7. Only then create production projects, signing, listings, privacy disclosures, and release assets.
