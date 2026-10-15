# Temporary internal development branding

**TEMPORARY DEV ASSET — NOT APPROVED FOR PUBLIC RELEASE**

Status: **DEV ONLY / NOT RELEASE CLEARED**.

`development_assets.json` is a new supplemental development record. Its 54 asset
entries specify path, SHA-256, purpose, temporary/internal/generated provenance,
historical counterpart and intended replacement with owner-cleared production art.
The primitive OLA / DEV images were generated locally without external artwork or
font inputs. They are placeholders, not proposed final logo designs.

| Development location (relative to budget) | Images | Selection |
|---|---:|---|
| assets/icon/ola_dev_* | 4 | Explicit Flutter asset-bundle aliases |
| android/app/src/debug/res/ | 21 | Standard Android debug resource overlay |
| ios/Runner/Assets.xcassets/OlaDevAppIcon.appiconset/ | 21 | DevelopmentBrand.xcconfig via fixed debug wrapper |
| ios/Runner/Assets.xcassets/OlaDevLaunchImage.imageset/ | 3 | Launch storyboard |
| web/branding/dev/ | 5 | index.html and development manifest |

The four Flutter files use a DEV filename prefix inside an already declared asset
directory because pubspec.yaml is frozen historical evidence. The original files
remain present and unchanged. This layout deliberately preserves the meaning of
the checkpoint evidence; it does not claim the development files were in that
checkpoint or are approved for release.

From budget:

```text
python tool/brand/generate_development_assets.py --check
python tool/brand/check_development_assets.py --check
python tool/brand/check_development_assets.py --frozen
python tool/brand/check_development_assets.py --release
flutter test test/brand
flutter build apk --debug --flavor development --dart-define=OLA_ENVIRONMENT=development
```

The first command checks reproducibility; omit --check only to regenerate these
same DEV files. The frozen check validates all 1,980 recorded historical file
hashes and the immutable evidence-index hash. The release command intentionally
exits 1 with:

**TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED**

The Dart compile-time guard blocks release/profile builds and production
environment defines; the standalone release check independently fails closed. No release artifact is approved here.
Debug development and staging remain available. On macOS, after the existing
Flutter/CocoaPods setup, `sh tool/brand/build_ios_dev.sh` selects only the fixed
development simulator debug configuration. It does not modify frozen project or
scheme files. Native iOS validation remains required on macOS.

Before public release, replace the DEV images with cleared assets, review
production packaging (including inherited assets), and explicitly review removal
of the guards. Never rewrite historical evidence to describe new product artwork.
