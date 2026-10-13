# gRPC Java exact release evidence

Evidence-only remediation from 0f6f7b2ad8f44dc3f31eda01b0e85c21a554aa7d. Do Not Ship remains. Historical 7f3209eebb270aaef11d875c0d214467619a0627 remains NOT RECOVERED.

Seven io.grpc modules were derived from the retained productionRelease compile/runtime graph, all version 1.57.2. All are transitive/runtime-configured; this is not final release-binary inclusion evidence. Per-record Flutter/plugin ancestors are recomputed from graph edges. Exact Maven POMs, source JARs, six binary JARs and the Android AAR are retained. No Gradle module metadata is advertised by these POMs; attempted .module URLs returned 404. The AAR is graph-matched, not substituted by a missing grpc-android JAR.

Pinned upstream v1.57.2 resolves to 0cfa2d1e1d1baf229aaaf825c2b8ffd405d6e50c. The exact source archive, API tag response, root LICENSE, NOTICE.txt, module build scripts and vendored OkHttp licence are retained within a content-addressed upstream ZIP. The archive contains other upstream modules as release context only; this task does not classify them. It is not a reproducible build or final Corresponding Source assertion.

| Coordinate | Declaration | Classification |
|---|---|---|
| io.grpc:grpc-android:1.57.2 | Apache-2.0 | Verified with conditions |
| io.grpc:grpc-api:1.57.2 | Apache-2.0 | Verified with conditions |
| io.grpc:grpc-context:1.57.2 | Apache-2.0 | Verified with conditions |
| io.grpc:grpc-core:1.57.2 | NOASSERTION | Needs Verification |
| io.grpc:grpc-okhttp:1.57.2 | NOASSERTION | Needs Verification |
| io.grpc:grpc-protobuf-lite:1.57.2 | NOASSERTION | Needs Verification |
| io.grpc:grpc-stub:1.57.2 | Apache-2.0 | Verified with conditions |

## Distinct module scopes

- grpc-api includes four context-source files via its explicit context source set. Every source file is byte-matched to the exact upstream main/context tree. grpc-context is an empty compatibility JAR with a dependency on grpc-api; no implementation is inferred from its name.
- grpc-android is an AAR: classes.jar is recursively inventoried and matched to source filenames. BuildConfig is the exact published, trivial generated release/namespace metadata. Its content is checked against the retained upstream build configuration; no AGP or release rebuild is claimed. Empty R.txt, manifest/AAR metadata, and exact upstream ProGuard text are distinguished from implementation.
- grpc-api and grpc-stub have exact Apache source mappings. grpc-core GrpcUtil.iterableContains and grpc-protobuf-lite ProtoLiteUtils.copy explicitly copy Guava implementations. Their exact copied-source/attribution scopes remain unverified, so both modules remain NOASSERTION despite gRPC Apache headers. Service-provider metadata and nested provider class names are verified against the source archive. grpc-protobuf-lite contains adapter source, not a licence clearance for separately resolved protobuf-javalite.
- grpc-okhttp includes modified OkHttp source under okhttp/third_party/okhttp/main/java, explicitly selected by its build script. Retain its Apache licence, root NOTICE.txt and original Square/AOSP/Twitter/ASF headers. Four ASF-derived files refer to separately scoped NOTICE obligations not established here. StatusLine and Header identify OkHttp fork versions but lack file licence headers. The module remains NOASSERTION / Needs Verification pending that attribution/source-scope review.
- No Netty/BoringSSL/native transport module is selected in this seven-module cohort. Binary entries are recursively inventoried; compiled outer-class names must have published source files. This is an archive scope check, not bytecode-to-source reproducible-build proof. Separate protobuf, okio, Guava, annotations and other Maven dependencies retain their existing classifications. Namespace or import statements alone do not prove that their implementations are bundled.

## Reproduction and conditions

`python -B budget/tool/compliance/verify_grpc_evidence.py` verifies retained publisher hashes, graph binding, coordinates, plugin ancestors, source archive/tag identity, upstream source-file matches, archive inventories and conservative classifications. `--replay` reacquires the authoritative URLs and verifies immutable bytes (API responses are checked by commit identity). Dart independently recomputes the same archive audit while generating the SBOM. Missing or inconsistent evidence fails rather than falling back to project-family licence assumptions.

Preserve full Apache text, applicable source copyright/modification notices, root NOTICE.txt and the scoped OkHttp licence. Root NOTICE also discusses xDS/Envoy/PGV material outside this cohort; its retention is not evidence that those modules are included. No final notice bundle is generated here, and no notice obligation is waived because publisher JARs lack a named NOTICE file.

All four improved declarations are Verified with conditions. They are not legal/release clearance, production readiness, Phase 2A completion or final release-binary Corresponding Source. Production Android and iOS/native release verification remain incomplete. No application/build configuration, unrelated cohort or existing tag is changed.
