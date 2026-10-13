# Kotlin exact release evidence

Evidence-only review from 598bf1c6a8a7689bfa00024ea6a7266cf4e9083b. Do Not Ship remains. Historical checkpoint 7f3209eebb270aaef11d875c0d214467619a0627 remains NOT RECOVERED.

The nine records were derived from the unresolved current Android graph. They are all transitive. The manifest retains exact Maven Central POM, available Gradle module metadata, source JAR, graph-matched binaries, and per-coordinate graph plugin ancestors. BOMs are POM-only metadata, not runtime implementations. The multiplatform coroutine core metadata publication and its JVM child are separate. No reflection, serialization, compiler/plugin, JetBrains annotations or third-party Kotlin-using modules are silently included.

| Exact coordinate | Technical declaration | Classification | Distribution scope |
|---|---|---|---|
| org.jetbrains.kotlin:kotlin-bom:1.8.22 | Apache-2.0 | Verified with conditions | metadata only |
| org.jetbrains.kotlin:kotlin-stdlib:1.9.0 | Apache-2.0 AND BSL-1.0 | Verified with conditions | runtime configuration; inclusion unverified |
| org.jetbrains.kotlin:kotlin-stdlib-common:1.9.0 | Apache-2.0 | Verified with conditions | runtime configuration; inclusion unverified |
| org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0 | Apache-2.0 | Verified with conditions | runtime configuration; inclusion unverified |
| org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3 | Apache-2.0 | Verified with conditions | runtime configuration; inclusion unverified |
| org.jetbrains.kotlinx:kotlinx-coroutines-bom:1.7.3 | Apache-2.0 | Verified with conditions | metadata only |
| org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3 | Apache-2.0 | Verified with conditions | metadata only |
| org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.7.3 | NOASSERTION | Needs Verification | runtime configuration; inclusion unverified |
| org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3 | Apache-2.0 | Verified with conditions | runtime configuration; inclusion unverified |

## Source and licence scope

Published source JARs are the authoritative exact release snapshots; this does not assert a reproducible binary rebuild. The pinned upstream tags/commit API responses provide independently reacquirable context. Source mappings record byte-identical upstream files for headerless declarations/implementations and the Boost-derived math file. Other source files carry JetBrains Apache headers. Every archive entry has a retained hash inventory; each importer/replay recomputes it from the exact archive rather than trusting review flags.

Kotlin stdlib 1.9.0 includes MathJVM.kt with Boost-derived inverse hyperbolic functions (Eric Ford and Hubert Holin). The exact Kotlin release licence README scopes that file to BSL-1.0; the full Boost text is retained. Apache-2.0 AND BSL-1.0 expresses simultaneous file scopes, not an OR licence choice. GWT-derived collection code and Guava-derived utilities preserve Apache text and original Google/Guava source attribution; their exact upstream licence texts are retained. No compiler-wide third-party inventory is assigned to the runtime library.

Kotlin's repository NOTICE explicitly describes the compiler distribution; retaining it as context does not establish compiler inclusion. kotlinx.coroutines has its own library NOTICE; preservation of that NOTICE and applicable Apache text/copyright is a condition of the coroutine declarations. No standalone licence/NOTICE named entries were found in these exact source/binary JARs. That absence does not remove upstream notice obligations. This task creates evidence mappings, not a final distribution notice bundle or legal conclusion.

kotlin-stdlib-jdk8 1.9.0 is an empty compatibility artifact: its source JAR contains only module-info.java and its binary only metadata/module declaration. Dependencies remain separately classified. kotlin-bom 1.8.22 uses its own release context, not the stdlib 1.9.0 context. Coroutine core is a multiplatform parent; its non-selected metadata JAR is retained as reference evidence only. No native publication is claimed as an Android binary.

kotlinx-coroutines-core-jvm remains Needs Verification / NOASSERTION: its embedded DebugProbesKt.bin needs a separate exact source/build mapping. The top-level Apache POM and project licence do not clear this payload. Four _COROUTINE classes are present alongside normal coroutine classes; they are recorded in the complete binary inventory, not treated as a new package or compiler clearance. The conditional classification of the parent/other coroutine modules does not clear this unresolved dependency.

## Reproduction and limits

Run `python -B budget/tool/compliance/verify_kotlin_evidence.py` to replay retained hashes, exact publisher identities, archive inventories, source mappings, licence/NOTICE evidence and conservative classifications. `--replay` reacquires exact publisher/raw upstream bytes and rechecks tag-to-commit identity. Dart independently replays the same archives and validates Gradle module checksums/reciprocal parent publication when generating the inventory. The locked graph and application configuration are unchanged.

All declarations are technical evidence classifications with conditions. They are not legal clearance, release clearance, production readiness, Phase 2A completion, final notices, or final release-binary Corresponding Source compliance. Production Android build and iOS/native verification remain incomplete. Other cohorts are unchanged; seven release-gap groups remain.
