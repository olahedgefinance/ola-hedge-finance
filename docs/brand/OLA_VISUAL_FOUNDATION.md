# ÓLA visual foundation — Phase 5A

ÓLA HEDGE FINANCE is the full product name; ÓLA HEDGE is the compact name.
ÓLA means wealth/prosperity. HEDGE expresses protection, inspired by Job 1:10.
FINANCE describes the user's financial life. Internal brand idea: **Wealth under protection**.
The product UI remains broadly usable; this internal meaning does not introduce religious UI copy.

## Consumption

Import `package:budget/brand/ola_theme.dart` for `OlaPalette`, `OlaTheme`,
`OlaSpacing`, `OlaRadii` and `OlaElevation`. `colors.dart` integrates the scheme
when the selected accent is ÓLA Emerald and system-accent mode is off.
New installations default to Inter/Emerald. Existing persisted font, custom
accent, system color, high contrast and OLED preferences retain their values.
Font settings expose Inter explicitly. No schema or preference migration is added.

| Foundation | Values |
|---|---|
| Brand | Midnight #0B1220; Emerald #16A37A; Mint #6EE7C7; Blue #3B82F6; Gold #D6A84B |
| Typeface | Bundled Inter regular and bold; existing font bytes and notices unchanged |
| Spacing | 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 |
| Radii | 8 / 12 / 16 / 24; StadiumBorder for a height-independent pill |
| Elevation | 0 flat; 1 raised; 3 overlay |
| Surfaces | #F8FAFC canvas and white cards; Midnight canvas and #172235 dark surfaces |
| Text | Midnight / #475569 in light mode; #F8FAFC / #CBD5E1 in dark mode |
| Semantic | Darker success, warning, information and error roles in light mode; Mint, Gold and pale red in dark mode |

Emerald, Mint and Gold are paired with Midnight text. White on Emerald does
not meet the 4.5:1 normal-text target. Blue is a brand/data swatch; use the
darker information role for small light-mode text. Use semantic text/background
pairs from the scheme rather than placing a raw swatch on an arbitrary surface.
Automated tests cover normal text contrast for explicit scheme pairs and inherited
semantic labels, in both brightness modes. They do not certify every inherited
screen or every user-selected accent. Phase 6 must verify focus states, charts,
large text, screen readers and complete flows on target devices.

Only shared theme surfaces and defaults change. Screen-specific layouts, chart
series, category palettes, financial calculations, database migrations, storage
names and backup content stay unchanged. Export filename prefixes use `ola-hedge-`;
imports retain their historical Cashew wording and file-format compatibility.

## Temporary artwork and immutable history

**TEMPORARY DEV ASSET — NOT APPROVED FOR PUBLIC RELEASE**

The 54 plain OLA / DEV placeholders are internal visual-test assets. Their new
paths, SHA-256 hashes, purpose, generated provenance, DEV-only status and required
production replacement are recorded in `budget/brand/development_assets.json`.
This is supplemental current-development evidence, not a release-clearance record.
All historically evidenced files remain at their original paths with their exact
verified bytes. No historical manifest, report, hash or tag was amended.

Development integrations are explicit:

- Flutter: four `assets/icon/ola_dev_*` files use the existing bundled directory.
  `DevelopmentBrandAssetBundle` maps the four historical UI asset keys to these
  files beneath MaterialApp. The flat DEV prefix avoids editing frozen pubspec.yaml.
- Android: 21 files under `android/app/src/debug/res/` override the main resources
  only for debug builds. Historical main resources remain unchanged.
- iOS: separate `OlaDevAppIcon.appiconset` and `OlaDevLaunchImage.imageset` hold
  24 files. The launch storyboard selects the new splash set. On macOS use
  `sh tool/brand/build_ios_dev.sh` after the existing Flutter/CocoaPods setup;
  its fixed simulator debug invocation selects `DevelopmentBrand.xcconfig` and
  the development display-name plist. The historical Xcode project and schemes
  are unchanged. This wrapper has not been built on the Windows development host.
- Web: five icons plus the development PWA manifest live in `web/branding/dev/`.
  index.html selects these files explicitly.

The production base identity contracts stay unchanged. `developmentBrand`, the
development iOS plist and development PWA manifest provide the compact ÓLA HEDGE
name for internal use. Full product display identity remains ÓLA HEDGE FINANCE.
See `budget/brand/DEV_ASSETS.md` for validation and guard commands.

## Release guard

The app entrypoint instantiates a constant guard that rejects product/release,
profile and noncanonical environment values. Only empty/default, development and
staging debug environments are accepted. The standalone asset release check fails
closed even if its supplemental manifest is missing or corrupted. Each reports:

**TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED**

Ordinary development debug builds remain supported. Removing these guards requires
owner-cleared production artwork and a separate release review. Historical assets
may remain bundled in internal builds because the frozen asset declarations are
preserved; internal build success grants no permission to publish those assets.

## Identifier boundary and next phase

Retain Android/iOS `com.olahedgefinance.app`, existing `.dev` / `.staging` variants
and Dart package `budget`. No Firebase/cloud/OAuth/store identifiers change. No
domains or support contacts are invented. Production asset clearance, packaging
and any service migrations remain explicit owner decisions for subsequent work.

Phase 5B should supply cleared production artwork, define a reviewed production
packaging plan separate from immutable historical evidence, and verify native
masking, notification silhouettes, splash and PWA behavior on target devices.
Unrelated inherited illustrations, category assets and fonts retain their existing
attribution and release status. This phase does not provide new release clearance.
