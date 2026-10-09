# Native wrapper evidence collected 2026-10-09

This is new evidence for the canonical repository lockfiles. It is not the missing
historical supplement commit `48959137a32d9ff8c4a02c6b4707539b858e1ef1` and does
not recreate the missing verified checkpoint.

The inventory contains 25 wrapper mappings: 24 exact Pub archive downloads whose
SHA-256 values match `pubspec.lock`, and the clean `file_picker` Git checkout at
its locked revision. Retained upstream pubspec, license, podspec and available
Android metadata bytes were compared with the authenticated archives. All 24
retained file sets matched. File hashes and relative evidence paths are recorded
in `native-wrapper-cache-inventory.json`; download identities and hashes are in
`hosted-archive-authentication.json`. The archive binaries are retained outside
this directory and are not intended for repository import.

All 25 observed Pub identities and statically derived podspec versions match the
lockfiles. CocoaPods has NOT evaluated these specifications and their locked
specification checksums have NOT been replayed. Static pod versions do not prove
equivalent evaluated specifications. Root wrapper licenses do not establish
clearance for proprietary native SDKs, native transitive components, notices,
reciprocal source obligations or complete platform applicability.

Android evidence is declared configuration only. The app declares Firebase BoM
31.1.1 while the locked firebase_core package declares a default Firebase SDK/BoM
33.1.0. This collection contains no resolved Gradle dependency graph, Maven
POM/JAR/AAR authentication or Android release build. Exact resolved Firebase Auth
and Firestore versions remain unverified.

Run `pwsh -NoProfile -File verify-native-evidence.ps1` to check retained byte hashes
and consistency of the recorded evidence. It does not freshly download archives,
recheck Git, replay CocoaPods or certify release compliance. The collection and
authentication scripts describe how this evidence was obtained; collection uses
the original host paths, while every retained evidence path in the manifest is
relative to this directory. Source paths in metadata are historical provenance.

Current outcome: authenticated wrapper source evidence; native integration and
release obligations remain open. Do Not Ship.
