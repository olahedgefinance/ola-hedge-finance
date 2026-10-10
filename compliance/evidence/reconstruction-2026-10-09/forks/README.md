# Four source/fork delta evidence

This records exact source comparisons and inherited modifications, not release/legal clearance. Do Not Ship remains. Historical 7f3209eebb270aaef11d875c0d214467619a0627 NOT RECOVERED; the verified reconstruction tag is unchanged.

Two locked Git forks are compared to proven upstream ancestors (file_picker merge parent; reorderable_grid_view direct parent), verified against freshly acquired upstream Git histories and exact fork retrievals. Two vendored packages are compared to authenticated Pub release archives. Their upstream Git repositories are unavailable; their historical Git fork points are UNAVAILABLE and are not inferred. Archive version + SHA-256 + complete source-tree hash is the comparison revision. Canonical commit + subtree/tree hash is the target identity.

Each package directory retains complete before/after file inventories, raw SHA-256/Git blob identities/modes, all additions/modifications/deletions, a full binary-capable patch, root licences, source-header review, authorship/history where available, patch-application proof and a dated central modification record. No code or dependency is changed. Example deletions are recorded including binary files; line endings remain in raw hashes/patches and are separately classified to avoid exaggerating substantive changes. Source tree hashes use SHA-256 over canonical JSON (UTF-8, sorted keys, compact separators, newline) of the ordered file inventory. All archive modes in these two actual releases are 100644.

Replay from repository root:

```text
python -B budget/tool/compliance/verify_fork_evidence.py
python -B budget/tool/compliance/verify_fork_evidence.py --source-root <preserved-source-directory>
python -B -m unittest discover -s budget/test/compliance -p test_fork_evidence.py -v
```

The source directory contains file_picker.git, reorderable_grid_view.git, sliding_sheet.tar.gz and implicitly_animated_reorderable_list.tar.gz. Git histories can be reacquired from recorded upstream/fork URLs and exact commits; archive URLs/hashes are in manifest.json. These full source archives/histories are preserved outside Git to avoid embedding large upstream payloads. Normal replay binds retained evidence to the current lock, tracked canonical path trees and exact clean Git dependency checkouts in package_config.json. Full replay also rehashes upstream payloads, verifies ancestry and reproduces the full patches without running upstream source. Patches were independently applied through fresh external Git indexes and produced exactly the recorded target trees.

The Dart generator separately rejects stale lock identities, missing records/payload hashes, changed vendored trees or dirty/mismatched dependency caches before evaluating the closed technical gap. Evidence files are also bound by the central reconstruction SHA-256 index.

The technical fork-delta group is closed only for these complete source comparisons and modification records. Root MIT licence and retained source copyright/licence statements are preserved; no new ownership attribution is invented. Final notice delivery, combined-work/source-offer obligations, native builds, legal review and release-specific Corresponding Source remain separate open gates. No assertion of native binary verification is made.
