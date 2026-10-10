# CocoaPods exact-source evidence, 2026-10-09

This supplement is technical evidence, not release or legal clearance. Do Not Ship.
Base: `36fb5da48f28090de9187d6afcf78a637ebeea6a`. The historical supplement
`48959137a32d9ff8c4a02c6b4707539b858e1ef1` is unavailable and was not reused.
Historical checkpoint `7f3209eebb270aaef11d875c0d214467619a0627` remains NOT RECOVERED.

## Evidence and scope

`manifest.json` records all 29 registry podspecs in the current Podfile.lock.
Their SHA-1 values match the locked SPEC CHECKSUMS byte-for-byte. CocoaPods Core
1.15.2 `Specification#checksum` hashes the defining file; this is an independent
file-checksum replay, not execution of CocoaPods or upstream Ruby:
https://github.com/CocoaPods/Core/blob/1.15.2/lib/cocoapods-core/specification.rb

Each Git source has its exact podspec-declared commit or a retained tag-to-commit
receipt; annotated tags are peeled. Source licence text is retained from that
revision, at the podspec licence path or discovered root LICENSE when unspecified.
SwiftyGif's old repository redirects: its retained exact Git tree and blob provide
additional corroboration for LICENSE at the same resolved revision. The verifier
also binds the exact-revision contents API URL to the original source repository,
checks the retained response SHA-256, decodes its payload, and verifies its Git blob
identity. Other Git licences require the exact source-derived raw URL.

Two HTTP payloads (RecaptchaEnterprise and sqlite3) were acquired and SHA-256
recorded; those full archives are preserved outside Git. These observed digests
pin this acquisition, but the upstream podspecs do not provide independent archive
digests. The reCAPTCHA payload contains binaries and no separately named licence
file; a copyright statement is not a grant. SQLite's public-domain statement
is retained without inventing an SPDX declaration or asserting global legal effect.

The existing classifier independently examines actual licence text. Podspec
aliases must agree with that result. Mixed Firestore, GoogleUtilities, gRPC and
BoringSSL notices remain unresolved rather than being flattened to a primary
licence. Successful declarations are only `verified-with-conditions`;
`licenseConcluded` stays NOASSERTION. No automatic AND/OR expression is inferred.

`unresolved-start-inventory.json` covers all 32 initially unresolved CocoaPods,
including candidate Flutter package paths through the root-collapsed lockfile graph.
Quoted pod headings are parsed explicitly. Root collapse merges subspec edges,
so these paths do not prove selected subspec or binary inclusion. The existing
SBOM dependency relationships are not changed; this is source provenance, not a
new resolved binary graph. All are conservatively treated as potentially runtime
distributed; wrapper/umbrella metadata does not establish final binary inclusion.

`wrapper-reverification.json` rechecks all 25 earlier mappings: 24 Pub archives
rehash to locked SHA-256 and retained files match archive members. file_picker
files match its exact locked Git revision (only recorded CRLF checkout conversion
where applicable). Raw Ruby hashes do NOT match locked evaluated local-spec JSON
checksums; this is not evidence of source tampering and must not be called a
successful CocoaPods local-spec replay. No Ruby podspec is executed.

## Replay

From this directory, with Python 3 and Git available:

```text
python replay.py
python replay.py --online --archive-root <archive-directory> --wrapper-archives <prior-native-archive-directory>
```

Replay never writes the checkout, downloads/extracts no executable into the
project, and executes no upstream code. It checks retained hashes and bindings;
online mode also rereads authoritative URLs and checks current tags against
recorded immutable commits. A moved tag must fail, never silently update evidence.
The app's Dart generator additionally checks current lock identity, full registry
coverage, path safety, source references, licence hashes and classification.
The central reconstruction evidence index binds all files in this supplement.

## Remaining obligations

Exact Git revisions and archive URLs establish an acquisition route and source
version. Root licence files locate notices but do not establish complete selected
subspec or third-party coverage. Native `prepare_command` effects, submodules,
vendored frameworks and release-specific source/notice distributions remain to
be verified. Apache/MIT/BSD/Zlib declarations require review of applicable notices
and conditions; MPL source obligations require qualified review against actual
distributed files. These are engineering review tasks, not legal clearance.

`Flutter 1.0.0` is a local generated engine pod, not an exact engine revision;
the current local Flutter.podspec is absent. Its aggregate engine licensing must
not be replaced by the SDK's root BSD licence. The two ambiguous local wrappers
remain unresolved. All 8 release-gap groups remain open.

CocoaPods evaluation/install, local evaluated-spec checksums, Xcode/native builds,
native binary inspection and complete Corresponding Source:
**NOT TESTED — MACOS/NATIVE ENVIRONMENT BLOCKER**.
