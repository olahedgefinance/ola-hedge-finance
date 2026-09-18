# Build Status

Verification date: 2026-09-18

Source revision: `9cfbe50c16d95429891d44faf5f2c77a3abdb93b`

## Expected toolchain

`pubspec.yaml` declares Dart `>=3.0.0 <4.0.0`; the resolved lockfile requires Dart `>=3.3.0` and Flutter `>=3.19.0`. Repository history contains an explicit SDK bump to Flutter 3.19.6. The reproducible baseline used here was therefore:

- Flutter 3.19.6, framework revision `54e66469a9`
- Dart 3.3.4
- DevTools 2.31.1

The installed machine initially had no Flutter, Dart, Java, Android SDK, or Apple toolchain available on `PATH`. An exact, task-local Flutter 3.19.6 SDK and isolated package/tool caches were used. This did not alter the repository.

## Verification results

| Check | Result | Interpretation |
|---|---|---|
| Git status before work | PASS | Clean `main`, tracking `origin/main` |
| `flutter --version` | PASS | Exact expected Flutter/Dart baseline runs |
| `flutter pub get --enforce-lockfile` | PASS | Lockfile honored; no dependency upgrades |
| `flutter analyze --no-pub` | FAIL | 2 diagnostics: missing lint include and one bundled-package dependency-order info |
| `flutter test --no-pub` | FAIL | The sole application widget test is a stale Flutter counter template |
| `flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --no-pub` | PASS | Release web artifacts generated successfully |
| `flutter run -d web-server --release --no-pub` | PASS | App compiled, served on localhost, and returned HTTP 200 |
| Chrome launch | ENVIRONMENTAL FAIL | Chrome GPU/profile/remote-debug launch failed in the sandbox after compilation |
| Android build/run | NOT RUN | No Android SDK, JDK, emulator, or device was available |
| iOS build/run | NOT RUN | iOS builds require macOS/Xcode; audit host is Windows |
| Windows desktop build | NOT APPLICABLE | A Windows device exists, but the repository has no `windows/` platform project |

## Dependency installation

Dependencies resolved from the committed lockfile, including the two Git-hosted forks used by the application. No package was upgraded. Pub reported many newer incompatible versions, which were intentionally ignored because this audit is establishing the existing baseline.

The host Git installation initially failed HTTPS operations due to an incomplete helper/TLS setup. Using the bundled Git transport with its OpenSSL backend resolved dependency retrieval. This is an environment issue, not a source change.

## Analysis findings

The root cause is configuration-related: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, but `flutter_lints` is absent from `dev_dependencies`. Because that lint set did not load, this result is not evidence that first-party code is lint-clean. The only other reported item is an informational unsorted-dependencies diagnostic in the bundled `implicitly_animated_reorderable_list` package. No fix was attempted because this audit preserves the clean-source baseline.

Recommended minimal follow-up in Phase 0:

1. Add the Flutter-lints package version compatible with Flutter 3.19.6 without upgrading the application dependency graph.
2. Re-run analysis with the intended lint configuration active and capture that output as the meaningful baseline.
3. Classify any resulting diagnostics into defects, deprecations, generated/bundled code, and style debt before enforcing additional lints.

## Test findings

`budget/test/widget_test.dart` is the generated counter-app test. Its `pumpWidget` call is commented out, but it immediately expects the text `0`; the assertion therefore fails. This does not exercise Cashew. It should be replaced, not merely weakened, with tests for startup, transactions, calculations, migration compatibility, import validation, backup/restore, and sync conflict handling.

Tests inside locally bundled packages and the iOS template test target do not constitute application coverage.

## Runtime/build conclusion

The original source compiles into a release web application and runs on Flutter's web-server target at the expected historical toolchain. It is not yet a clean engineering baseline because analysis and application tests are red, and mobile builds remain unverified on this host. The failures are currently:

- configuration-related: missing `flutter_lints` development dependency;
- analysis-configuration-related: the intended Flutter lint set is not installed, so code-quality status is not yet established;
- test-related: stale placeholder test;
- environment-related: browser launch sandbox and absent Android/iOS toolchains.

No application defect was found that required a source change to produce the successful web build.

## Changes made during verification

No tracked repository file was changed for dependency installation or building. Flutter SDK, Pub cache, and generated build artifacts were isolated or ignored. No package, schema, Firebase configuration, or platform identifier was changed.

## Remaining baseline acceptance gates

- Verify a debug and release Android build on JDK/SDK versions compatible with the checked-in Gradle/AGP project.
- Run on at least one Android emulator/device and validate notification, widget, biometric, deep-link, purchase, and Google sign-in flows.
- Verify iOS build/signing on macOS/Xcode and run on simulator/device.
- Replace the placeholder test and add migration/financial smoke tests.
- Bring first-party static analysis to an agreed green baseline.
- Repeat web smoke testing in a normal browser environment.
