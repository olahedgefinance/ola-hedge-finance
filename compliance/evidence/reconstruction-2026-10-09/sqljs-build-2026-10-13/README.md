# SQL.js 1.6.2 source/build replay

Evidence-only bounded attempt from 8ee411033cfd475f3a1c9fdfc6cbdf18bd83f723. **Do Not Ship remains.** Historical 7f3209eebb270aaef11d875c0d214467619a0627 remains NOT RECOVERED.

## Result

**Build succeeds but provenance mismatch remains.** The source rebuild produced all three files, but none equals the shipped/published files, even after JavaScript line-ending normalisation. It is not called semantically reproducible. A limited Node smoke test passed for both engines (SQLite version/source ID, extension sqrt, JSON, insert/export/reopen); this does not prove browser/application behaviour or semantic equivalence.

## Authoritative source and compiler decision

SQL.js v1.6.2 annotated tag 122e8fdeba995e105a77265c401f3e2013f8a425 resolves to commit 997d56fb954b63e76cf8d549c4660c972381768e. npm gitHead agrees. The retained source ZIP, npm archive (SHA512 verified), API metadata and GitHub release ZIPs are independently hashed. GitHub and npm distributed bytes agree. Repository WASM is byte-identical to publication; JS differs only by CRLF line endings.

At that exact source commit, `.github/workflows/release.yml` invokes `.github/actions/build-sqljs`; its action uses `.devcontainer/Dockerfile` and `npm run rebuild`. The executable Dockerfile pins **Emscripten 2.0.29**. The Makefile and Dockerfile's **2.0.15** text are upstream historical comments, not local invention or an active version selection. This establishes the expected compiler, not the publisher's actual historical toolchain or byte reproducibility. No alternative compiler was chosen because it made a build succeed.

## Inputs and rights boundaries

- SQL.js package/source LICENSE and AUTHORS match; retain MIT text, named authors, and the separate Ryusei Yamaguchi Makefile attribution.
- SQLite amalgamation **3.36.0**, exact SHA3-256 from the unchanged Makefile, with its public-domain source header. That dedication is not automatically applied to contributed files or compiler runtime libraries.
- `extension-functions.c`: exact upstream-pinned SHA1 c68fa706d6d9ff98608044c00212473f9c14892f. The official legacy endpoint and alternate official routes returned HTTP 503. A contributor-hosted copy is retained at an exact Git commit and matches that checksum; the original URL, failed attempts and mirror provenance remain explicit. This source invokes several contributor names but does not contain an explicit licence grant in its header; retain licence/attribution review as an open condition. `RegisterExtensionFunctions` is exported and called by upstream src/api.js, so this is not treated as unused source.
- Emscripten/LLVM/musl runtime notice/source scope and final release-specific source/notices delivery remain unverified. This evidence is not final Corresponding Source or legal clearance.

## Isolated reproduction

The new tools/evidence verifier is `budget/tool/compliance/verify_sqljs_evidence.py`; its `--replay` option reacquires immutable source/archive URLs and checks bytes. Mutable API responses are retained snapshots checked by exact identities, not asserted byte-stable forever. Unit tests exercise mismatch, unsafe path, wrong compiler/source, missing caveats and unsupported-clearance cases.

Actual toolchain: Emscripten 2.0.29 (28ca7fb7ce895b21013212e4644a5794a15a76f9), emsdk f9dee6673eb0692d79c45040448dfaafeb8842fb, Node 14.15.5 / npm 6.14.11, Python 3.9.2, GNU Make 4.4.1 w32, Git Bash 5.3.15, isolated Java 8u152 used by Closure. No global activation or project build configuration change. CMake is not used by these targets; the SDK contains prebuilt compiler tools. The Node/base-image/OS combination of the historical release is not fully digest-pinned by upstream.

Windows adaptations are recorded, not hidden: official Node ZIP contents re-extracted under the emsdk manifest's expected bin directory; short path aliases to avoid Make's space-tokenisation; exact downloaded inputs preseeded into cache; Python hashlib implements the same upstream SHA3-256 check where sha3sum was unavailable. No source/Makefile/optimisation flag modification. The first path failure and incomplete-directory retry are retained. The successful attempt starts from a fresh extraction.

Replay only the shipped targets with the unmodified upstream Makefile: `make SHELL=<Git-Bash-path> dist/worker.sql-wasm.js`. This includes sql-wasm.js and sql-wasm.wasm. It does not claim the upstream asm/debug/browser/npm test suite passed. Build command, cwd, all explicit environment overrides, source input hashes, compiler/version logs and output hashes are linked in manifest.json. All original source files were compared to the pinned archive after building. Inputs use content-addressed blobs; tool archives have SHA256 records and acquisition URLs/logs rather than embedding hundreds of MB of SDK binaries.

For another host: obtain and verify the recorded emsdk source ZIP and install/locally activate 2.0.29; verify all downloaded tool archive hashes, acquire the exact Make distribution if using Windows, then reproduce the recorded environment (using that host's absolute paths). Extract source.zip into a new external directory, copy SQLite and extension source into the named cache files, provide the retained SHA3 adapter or a compatible sha3sum, and run the recorded Make target. Preserve logs and compare every output. The Windows helper scripts are retained as session recipes with explicit paths, not advertised as universal installers.

## Shipping relationship and scope

`budget/web/index.html` loads sql-wasm.js. `budget/lib/database/platform/web.dart` uses Drift WebDatabase; pubspec.lock pins drift and drift_dev 2.18.0. SQL.js itself is vendored in web/, not installed by an ÓLA npm lockfile. The three files are shipping candidates in the web asset tree; actual worker invocation and final release-output membership were not proved in this task. The source archive/npm lock are upstream build inputs and do not replace the app's Flutter lockfile.

No shipped file was replaced. The three SQL.js package declarations remain MIT / verified-with-conditions; this records upstream package metadata, not clearance of every embedded contributor/runtime. Aggregate declaration counts are generated, not forced. The `web-sqljs-provenance` gap stays open due to the byte mismatch and source/notices conditions. Other cohorts and all existing tags are unchanged.

## SDK archive review follow-up

The installer removed its download ZIPs. The four exact URLs in the installation logs were reacquired, SHA-256 recorded, and all original regular archive members compared against the installed tool trees. One difference is explicitly recorded: the pinned installer rewrites emscripten-version.txt with Windows CRLF; all executable/script bytes match. The content-addressed comparison records paths/hashes; generated cache/extra files are excluded. This is qualified post-installation correspondence, not a claim that original download-time archive hashes were captured. SDK ZIPs remain in the external session workspace, not in Git. Two fresh-source builds produced identical outputs, with the first-run SDK runtime cache reused by the second.
