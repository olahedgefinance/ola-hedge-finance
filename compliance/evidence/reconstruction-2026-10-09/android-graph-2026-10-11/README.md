# Android dependency graph — 2026-10-11

Evidence-only diagnostic from source commit `db04e9087b545568ede24982cc2572d0c3cca1ef`. Do Not Ship remains. Historical `7f3209eebb270aaef11d875c0d214467619a0627` was NOT RECOVERED.

## Scope and result

Unchanged application scripts resolved `productionReleaseRuntimeClasspath`, `productionReleaseCompileClasspath` and `coreLibraryDesugaring`. A second run with `--refresh-dependencies` reproduced normalized graph nodes, requested/selected edges, constraint flags, artifact sizes and SHA-256 values exactly. Raw observations retain repeated identical artifacts from multiple variants. No Gradle verification metadata or dependency lock was written to the project.

All 29 applied Android plugins (application plus 28 Flutter modules) used AGP 7.3.1. Some plugin buildscript classpaths resolved newer AGP requests, including 8.3.1; those requests did not replace the parent-loaded applied plugin. This observation is specific to this source/toolchain, not a general compatibility guarantee. No AGP or wrapper change was required for resolution.

`:app:checkDevelopmentDebugAarMetadata` and `:app:assembleDevelopmentDebug` passed. No production/release build, runtime device test, signing review, release-binary reconciliation or deployment was performed. The existing lint configuration was not changed; a successful debug assembly is not comprehensive Android validation.

## Replay

Use an isolated Temurin JDK 17.0.20.1+1, exact Gradle 7.5 and Android SDK. `toolchain.json` records exact distribution identities, installation paths and process environment used. The unchanged plugins required SDK platforms 30–34 and build tools 30.0.3; additional platforms were installed only into the isolated SDK by Gradle. No project SDK level or global environment was changed.

Restore the pinned Flutter 3.19.6 / Dart 3.3.4 SDK and Pub dependencies from the unchanged lockfile. Authenticate plugin `android/build.gradle` against each `plugin-inputs.json` exact archive SHA-256, or the file_picker Git revision/blob. Every hosted script was compared byte-for-byte with its locked Pub archive; the Git script was compared with its exact Git object with CRLF normalization. These mappings do not substitute for native licences.

From `budget/android`, with process-scoped JAVA_HOME, GRADLE_USER_HOME, ANDROID_HOME, ANDROID_SDK_ROOT, ANDROID_USER_HOME, PUB_CACHE and PATH set as recorded, run the external Gradle distribution:

```text
gradle --no-daemon --console=plain --max-workers=2 --project-cache-dir <isolated-cache> --init-script <evidence>/inspect-plugins.init.gradle --stacktrace :app:dependencies --configuration productionReleaseRuntimeClasspath
```

Set `OLA_GRAPH_OUTPUT` to an external JSON path, then:

```text
gradle --no-daemon --console=plain --max-workers=2 --project-cache-dir <isolated-cache> --init-script <evidence>/inspect-plugins.init.gradle --init-script <evidence>/export-graph.init.gradle --stacktrace --refresh-dependencies olaExportAndroidGraph
```

Compare output to `resolved-graph.json` after replacing only artifact `file` absolute paths with basenames. Every other field must agree. Rehash the actual downloaded cache files. Fetch the five exact Google Maven artifact URLs in `target-provenance.json` and compare against graph SHA-256 values. The current run independently downloaded all five and matched them. A 404 source JAR means only that the exact queried URL was unavailable, not that source cannot exist elsewhere.

The exporter only observes configuration and registers a reporting task via an external init script. It changes no repository build script, dependency constraint, AGP selection, variant, SDK level or signing setting. Published module artifacts are hashed; project output binaries are explicitly outside this graph's artifact scope.

## Conservative inventory integration

The graph adds 126 previously absent module identities. The 450-package inventory contains 138 Maven components: 135 graph modules plus three pre-existing build tools. Unresolved declarations rise from 33 to 160: +126 unreviewed new modules and +1 selected Firebase BOM 33.1.0, for which previous 31.1.1 licence evidence cannot be carried forward. This is coverage expansion, not a licence regression or clearance. The root still requests 31.1.1; actual selection is 33.1.0. All seven release gaps remain.

All five targeted licence declarations remain NOASSERTION / Needs Verification. Exact versions and acquisition hashes are verified, but metadata alone does not close their source/licence obligations:

- desugar_jdk_libs 1.2.2: POM declares GPL v2 with Classpath Exception; exact source/licence mapping remains incomplete.
- Play review and review-ktx 2.0.1: custom Play Core SDK terms and embedded licence payloads retained; no automatic SPDX/rights clearance.
- Firebase Auth 23.0.0: POM declares Android SDK terms, not Apache-2.0. No source JAR was available at the queried exact URL.
- Firestore 25.0.0: Apache-2.0 POM, exact source JAR hash and embedded third-party notices retained. Complete component licence scope and source-to-release-binary mapping remain unverified.

The importer records all graph modules, maps Flutter project nodes back to exact Pub packages, and excludes constraint edges from SPDX DEPENDS_ON relationships. BOM metadata and the desugaring configuration artifact are non-distributed; runtime-selected binary modules are conservatively potential distribution. That flag is not proof of inclusion in a shipped binary. New modules retain NOASSERTION rather than inheriting a parent's licence. Existing exact-version licence evidence is preserved only when the selected version matches.

The Android release-gap finding now records successful graph/debug diagnostics while retaining native licence/source and production artifact verification blockers. No final notices or Corresponding Source release mapping was cleared.
