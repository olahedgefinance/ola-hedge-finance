# Release compliance bundles

`dart run tool/compliance/generate_sbom.dart --version <version>` creates the reproducible machine-generated evidence for:

```text
compliance/releases/<version>/
  sbom.spdx.json
  dependency-licence-report.md
```

Before a real release, add a completed `release-manifest.json` based on `../release/release-manifest.template.json`. The manifest points to the exact commit and immutable tag, Corresponding Source URL/archive and hash, binary artefact hashes, build reference, third-party notices, and the human approval checklist. The source archive and binaries may remain in an approved ignored artefact location when their hashes and durable published locations are recorded.

Do not create placeholder production tags or fabricate approvals. Do not commit secrets, signing keys, private Firebase configuration, or credentials. A generated directory is release evidence only when strict validation passes against the exact clean tagged tree and qualified review is complete.

