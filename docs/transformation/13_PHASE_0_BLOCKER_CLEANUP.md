# Phase 0 Blocker Cleanup

Implementation date: 2026-09-18

## Scope and outcome

This follow-up clears the two narrow integration blockers left after the repository audit and Phase 2 brand foundation:

1. the only general widget test was an inactive Flutter counter-template test;
2. `analysis_options.yaml` referenced `package:flutter_lints/flutter.yaml`, but the package was not declared.

No production behavior, financial logic, database schema or migration, cloud configuration, protected service identifier, or approved OLA Edge Finance branding was changed.

## Root causes and changes

### Stale widget test

`budget/test/widget_test.dart` had its `pumpWidget` call commented out and immediately searched an empty widget tree for the generated counter sample's `0` text. This could not test Cashew and failed deterministically.

It was replaced with a minimal application-shell smoke test. The test constructs a `MaterialApp` from the canonical `appBrand.productName` value and verifies both its configured title and rendered text. This keeps the test independent of database, Firebase, plugins, and platform initialization while exercising the current identity boundary.

Commit: `d6d23c3 test: replace stale counter smoke test`

### Missing lint dependency

The repository's analyzer configuration includes Flutter's standard lint rules, but `pubspec.yaml` did not provide that package. The Flutter 3.19.6 application template declares `flutter_lints: ^3.0.0`; the same compatible constraint was added under `dev_dependencies`, along with the explicit Flutter SDK test dependency used by the test suite.

Dependency resolution added only:

- `flutter_lints 3.0.2` as a direct development dependency;
- `lints 3.0.0` as a transitive dependency.

`flutter_test`, which was already present in the lockfile transitively, is now correctly marked as a direct development dependency. No application dependency or SDK constraint was upgraded.

Commit: `18e0011 chore: restore Flutter lint configuration`

## Verification

Verified with Flutter 3.19.6 and Dart 3.3.4:

| Command | Result |
|---|---|
| `flutter pub get --enforce-lockfile --offline` | PASS |
| `flutter test test/widget_test.dart --no-pub` | PASS |
| `flutter test --no-pub` | PASS — 8/8 tests |
| `flutter analyze test/brand test/widget_test.dart --no-pub` | PASS — no issues |
| `flutter analyze --no-pub` | FAIL — 5,275 findings: 0 errors, 140 warnings, 5,135 infos |

The missing lint include no longer appears. The nonzero full-analysis result is now a truthful view of historical repository debt rather than a broken analyzer configuration. The most numerous categories include `prefer_const_constructors`, string interpolation style, flow-control braces, `avoid_print`, asynchronous build-context use, file naming, and deprecations. These were not mass-edited.

## Remaining baseline gates

- Triage the 140 analyzer warnings, prioritizing correctness and deprecations over style-only infos.
- Decide whether bundled/generated sources should be excluded or remediated before adopting a CI lint threshold.
- Add meaningful coverage for calculations, database migrations, import validation, backup/restore, and sync conflicts; eight passing tests are a green suite, not comprehensive coverage.
- Verify Android debug/release builds and device flows with a compatible Android SDK/JDK environment.
- Verify iOS build, signing, and runtime behavior on macOS/Xcode.
- Re-run browser smoke testing outside the current sandbox constraints.

Because full analysis still exits nonzero and mobile targets remain unverified, this work is intentionally not presented as a fully accepted production baseline. It clears the two identified integration blockers without broadening into lint remediation or feature work.
