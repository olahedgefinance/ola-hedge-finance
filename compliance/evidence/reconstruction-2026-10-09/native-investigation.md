# Native evidence investigation — 2026-10-09

Canonical repository: `C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE`.
Governance read: root AGENTS.md and docs/project/CANONICAL_REPOSITORY.md.
Read-only verifier passed at `eb4adf8b6b8d8117bdf5f9ffa7288c6e42e3e94f`, branch
`compliance/reconstruct-verified-baseline-2026-10-09`. Ten pre-existing untracked
handoff/report documents were observed. No repository mutation was performed by
this investigator. Evidence writes are only in the assigned external audit area.

## Historical supplement not recovered

With `GIT_NO_LAZY_FETCH=1`, explicit read-only Git object checks in the old Cashew
object database fail for `48959137a32d9ff8c4a02c6b4707539b858e1ef1` and
`eccb068bc489e33f7fd7e0d6d801898a3a3b9767`. The prior local search report records
the same absence. The older preserved Phase 2A worktree has SBOM tooling but no
`compliance/evidence/2026-10-04-native` evidence tree.

The report's `/workspace/scratch/4b0553d791c9/ola-native-evidence-2026-10-04.bundle`
is a cloud workspace path, not an accessible local bundle. Its reported SHA-256
`060379273c9fd1f4ed1006e4880a2c481c861d8e2fc25464127f6533936135a9` is historical
metadata only and was not independently verified here. Neither that report nor
its 25-mapping claim establishes current native verification.

Preserved sources below are under
`C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE-recovery\pre-migration-20261008`:

| File | Fresh SHA-256 |
|---|---|
| all-surviving-refs.bundle | f98a4a17e853709c09e06d496d083e646e56ce86f96c662784f43137e73d5b41 |
| reports/SIX_GAP_CONTINUATION_2026-10-04.md | bf9c5a82fb5ca54687706b9ce9a9b85b66f685b50005bcffe9fefb593b6cfeb5 |
| reports/RECOVERY_AND_INTEGRATION_REPORT.md | 56f1081bf54a6d847d7142d5868ee285f70c8d3f5572348518970822b82b38ed |
| reports/CODEX_CHECKPOINT_SEARCH_REPORT.md | fa86b409651fe058060c21874744dcc35ec3497728be79e18234dc3b60fad09e |

## Fresh independently collected wrapper evidence

Root authorized fresh collection after the historical supplement was not found.
The output is `native-evidence/` adjacent to this report. It includes:

- `native-wrapper-cache-inventory.json`: 25 mappings, 134 retained file hashes.
- `hosted-archive-authentication.json`: exact URLs and actual/expected hashes for
  24 Pub archive downloads, all matching current canonical `pubspec.lock`.
- 101 archive member byte comparisons covering all retained non-cache files for
  those 24 hosted packages: all match.
- `file-picker-git-identity.json`: clean Git checkout at exact locked revision
  `ccbb9a384491cc0759f94618bb3859411e228091`; underlying bare-cache origin is
  `https://github.com/melWiss/flutter_file_picker.git`, matching the lock identity.
- Exact upstream LICENSE, pubspec and podspec bytes plus available Android
  declarations and Firebase iOS SDK helper; no whitespace normalization.
- Collection, authentication and offline verification scripts plus SHA256SUMS.

All 25 Pub identities/versions and static pod versions match current lockfiles.
This is not CocoaPods-evaluated specification-checksum verification; every row
explicitly records `cocoapods_evaluated=false` and `spec_checksum_verified=false`.

| Wrapper | Locked Pub | Locked/static pod |
|---|---|---|
| app_links | 6.1.4 | 0.0.1 |
| app_settings | 5.1.1 | 5.1.1 |
| cloud_firestore | 5.1.0 | 5.1.0 |
| device_info_plus | 10.1.0 | 0.0.1 |
| file_picker | 6.0.1 | 0.0.1 |
| firebase_auth | 5.1.2 | 5.1.2 |
| firebase_core | 3.2.0 | 3.2.0 |
| flutter_charset_detector_ios | 1.0.2 | 0.0.1 |
| flutter_local_notifications | 17.2.1+2 | 0.0.1 |
| flutter_timezone | 1.0.8 | 0.0.1 |
| google_sign_in_ios | 5.7.6 | 0.0.1 |
| home_widget | 0.5.0 | 0.0.1 |
| image_picker_ios | 0.8.8+4 | 0.0.1 |
| in_app_purchase_storekit | 0.3.17 | 0.0.1 |
| in_app_review | 2.0.9 | 0.2.0 |
| local_auth_darwin | 1.3.1 | 0.0.1 |
| package_info_plus | 8.0.0 | 0.4.5 |
| path_provider_foundation | 2.4.0 | 0.0.1 |
| quick_actions_ios | 1.0.6 | 0.0.1 |
| recaptcha_enterprise_flutter | 18.5.1 | 18.5.1 |
| share_plus | 10.0.0 | 0.0.1 |
| shared_preferences_foundation | 2.4.0 | 0.0.1 |
| sqlite3_flutter_libs | 0.5.15 | 0.0.1 |
| system_theme | 3.0.0 | 0.0.1 |
| url_launcher_ios | 6.3.1 | 0.0.1 |

Current canonical lockfile byte hashes:

- pubspec.lock: `8a7ce3864eab7f69bf6cd5a6c08aedf99c44697540a0fa8f639a8845c9757051`.
- ios/Podfile.lock: `a1ba8cc361413512b07015a828c9e4682d060166db95873c39d97108f9a3dbc5`.
- Older Phase 2A pubspec.lock differs:
  `1ade29152428138ab50b39f1c3915f433ac21bb31a4b8b9446cd49461214f3b0`;
  older Podfile.lock has the same hash as canonical.

Output manifest SHA-256:

- native-wrapper-cache-inventory.json:
  `0534771da0db01d4fd23e49f005cd127a29e8783f18e06cdf05506d99538c666`.
- hosted-archive-authentication.json:
  `8dfc216cbe19065078e406257d867c212386453cd2370fa7e06299d9de09a13d`.
- file-picker-git-identity.json:
  `dfe960389bc77de748fbfa53a1d8b376560d0d8454908536516b6c41086149af`.

## Available caches and Android limitations

Old working root:
`C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work`.
Available directories include `pub-cache/hosted/pub.dev`, `pub-cache/hosted-hashes`,
`pub-cache/git`, `flutter-sdk/bin/cache` (Dart SDK and artifacts), and
`tooling/sqlite-3.53.4-win-x64` (sqlite3.dll and retained ZIP). Root separately
handles running the pinned Flutter toolchain and application tests.

No Ruby, CocoaPods, Java or Gradle command was found on PATH. These tested
locations do not exist: user `.gradle`, user `.cocoapods`, user local Android SDK,
old-work userprofile `.gradle`, and old-work localappdata Android SDK. A targeted
file search in the Phase 2A worktree and those old userprofile/localappdata roots
found no Gradle lockfile, resolved dependency report, Maven POM, JAR or AAR.
This is scoped local absence, not a claim that no such material exists anywhere.

Canonical Gradle declares wrapper 7.5, Android plugin 7.3.1, Kotlin 1.9.0,
desugar_jdk_libs 1.2.2, app Firebase BoM 31.1.1, unversioned Firebase Auth and
Firestore, AndroidX Window 1.0.0, and Play review/review-ktx 2.0.1. The locked
firebase_core 3.2.0 package declares default FirebaseSDKVersion=33.1.0; package
Firebase Auth/Firestore depend on that selected platform. Consequently no exact
resolved native Auth/Firestore version is asserted from the app BoM alone.
Other exact declarations include reCAPTCHA 18.5.1 and sqlite3-native-library
3.41.2; these are declarations, not authenticated resolved binary evidence.

## Minimal port and remaining work

Copy `native-evidence/` into
`compliance/evidence/reconstruction-2026-10-09/native/`. Do not copy sibling
`native-archives/` (downloaded binaries and extraction working trees). Manifest
evidence paths are relative and survive the copy; source/cache paths are
historical host provenance only. Preserve external archives separately with
their already recorded hashes. Run `verify-native-evidence.ps1` after port.

Fresh verification run passed: 134 retained file hashes, 25 identity/static
version records, 24 archive authentication records and exact clean file_picker
Git identity record. Archive authentication itself freshly downloaded and
hashed all 24 archives, then compared 101 retained member byte hashes.

Still open: CocoaPods checksum replay; real platform builds; complete Android
resolved transitive graph; native SDK proprietary/custom terms; composite
license applicability (including image_picker_ios and charset detector);
native NOTICE and Corresponding Source obligations; Flutter binary/engine
linkage. This fresh evidence does not close all native release requirements.
No historical 37-NOASSERTION or 98-test claim is recreated. Do Not Ship remains.
