# Canonical repository governance

## Repository truth

- Official GitHub: https://github.com/olahedgefinance/ola-hedge-finance
- Canonical local Codex working copy: `C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE`
- Codex is the canonical code/repository executor. GitHub is the durable
  synchronization/source repository. A local branch is not automatically on GitHub.
- ChatGPT Work may research, analyse, update Notion and perform cross-system work.
  Work must not be the sole holder of repository changes.
- Notion records project/compliance status; it is not repository truth.
- Personal and Business environments are separate execution contexts. Temporary
  state is never authoritative. Both synchronize using this repository and exact
  commit identities, not workspace names or prose summaries. No account/API
  interoperability is assumed or required by this operating rule.

This is a project operating policy, not a claim that any tool automatically shares
files, permissions, memory, branches, or credentials with another tool.

## Start and end gates

Open the canonical folder as the Codex project. Existing chats can remain attached
to old folders: this setup does not relocate their execution context automatically.
Run `pwsh -NoProfile -File scripts/verify_canonical_repo.ps1` before editing. Stop on
FAIL. Review WARN items and record a known branch plus full 40-character HEAD.
The validator does not fetch. An authorized start-of-work fetch must be followed
by comparison; never automatically pull, merge, reset or overwrite local work.

Every Codex/Work handoff must record repository, branch, full HEAD, clean/dirty
working-tree status and purpose. Every repository-changing result must report
branch, commit SHA, parent SHA(s), files changed, checks run and push status.
Each session ends with commit and preservation metadata, or explicitly reports
uncommitted/incomplete work and its file/patch backups. Do not pretend an untracked
document or uncommitted patch belongs to a commit.

Before switching tool, Personal/Business context, cloud/local environment or
machine, important work must exist as a pushed commit or a verified Git bundle.
Important compliance/release checkpoints should have both, with user permission
for the push. Also preserve dirty/untracked/required ignored files separately,
with hashes; Git bundles contain committed reachable history only. Copy bundles
off the working machine to owner-approved durable storage. Two directories on the
same disk protect against accidental checkout loss, not device failure.

No autonomous GitHub push without explicit user permission. This clone sets
`push.default=nothing`, `pull.ff=only`, `fetch.prune=false`, and `gc.auto=0` locally.
These are guardrails, not server-enforced access control. Origin remains the
official repository. Upstream Cashew is fetch-only by policy, with its local push
URL set to `https://example.invalid/NO_PUSH`. Never push to upstream. Reapply these
local settings on new clones; they are not carried by a bundle.

## Branch policy

| Branch | Purpose |
|---|---|
| `main` | Stable source; promote only after project-specific verification/review |
| `develop` | Integration branch; merge approved work deliberately |
| `feature/*` | Product development |
| `fix/*` | Fixes |
| `compliance/*` | Compliance/evidence work |
| `release/*` | Release candidates |
| `codex/*` | Isolated repository/tooling tasks such as this governance setup |

Legacy `phase-*` branches remain at their original commits. Do not rename/delete
them just to fit the scheme. On setup, `develop` starts at official `main`
(`82d728a6bd7b5043b0b3bb37f66e0b2b41dae3eb`), with no misleading tracking of
`origin/main`. The governance branch starts at the surviving Phase 2A baseline
`6a8a37668ce6b34761026e8594ae80a55ec2b851`. It is not silently merged into main or
develop. Phase 5 remains separate at `d80b244ffc088162ce30658a7abbaf677505e8c0`.
The owner must approve eventual integration and pushes. Branch protection on
GitHub must be checked by the owner; this task does not configure or certify it.

## Lost-checkpoint rule

`7f3209eebb270aaef11d875c0d214467619a0627` and documentation prefix `03915b45`
remain historical/unavailable. Never reconstruct a missing verified Git
checkpoint from prose, Notion, counts, reports or regenerated files. The surviving
baseline is not a substitute for that missing verified state. Neither the separate
native supplement nor continuation reports were integrated during setup.

## Preservation inventory, 2026-10-08

All three old worktrees below share
`C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work\Cashew\.git`.

| Old worktree under that `work` directory | Branch | HEAD | State before migration |
|---|---|---|---|
| `Cashew` | `phase-2d/privacy-data-compliance-architecture` | `53024f373b3cb66eb3e7c13d0f2afbe41a8a3287` | One untracked privacy document |
| `Cashew-phase-2a-sbom` | `phase-2a/spdx-sbom-release-compliance` | `6a8a37668ce6b34761026e8594ae80a55ec2b851` | Clean |
| `Cashew-phase-5-rebrand` | `phase-5/rebrand-existing-application` | `d80b244ffc088162ce30658a7abbaf677505e8c0` | Clean |

Fresh official remote tips matched cached origin refs. There were no local branch
commits absent from origin history. All nine old local branch names and their
commit identities were retained in the canonical clone; five names were local-only.
The 49 existing tags remain. No old worktree or repository was removed.

Safety directory:
`C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE-recovery\pre-migration-20261008`

- `all-surviving-refs.bundle`: all 67 advertised refs, including worktree heads;
  complete history; SHA-256
  `f98a4a17e853709c09e06d496d083e646e56ce86f96c662784f43137e73d5b41`.
- `PRE_MIGRATION_INVENTORY.json`: refs, branches, worktrees, fresh remote heads/tags,
  copied-file paths, sizes and SHA-256 values.
- `uncommitted/17_PRIVACY_DATA_COMPLIANCE.md`: exact copy of the pre-existing
  69,844-byte untracked privacy document; SHA-256
  `455c404fcd3c4f98b056c96acfbb009146d391beb0c24d64285102ec2283b6a5`.
  It remains untracked in the old worktree and has NOT been silently added to this
  branch. Review it before a separately authorized integration.
- `uncommitted/17_PRIVACY_DATA_COMPLIANCE.patch`: additional applicable-but-not-
  applied preservation patch; SHA-256
  `7f00a4bdea8d9e5cd25641aa520d03472608d9ec5163ab8d20b62bb4be7638c5`.
- `reports/`: copied search/Windows recovery evidence and available downloaded
  recovery/continuation reports. These are evidence of past searches, not recovered
  commits or a new compliance assertion.

## Checkpoint operation

Requires PowerShell 7.4+ and Git on PATH; neither is an application runtime change.

```powershell
Set-Location 'C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE'
pwsh -NoProfile -File scripts/verify_canonical_repo.ps1 -RequireClean
pwsh -NoProfile -File scripts/create_checkpoint.ps1 -Name 'setup-example' -DryRun
pwsh -NoProfile -File scripts/create_checkpoint.ps1 -Name 'setup-example' -RunTests -CreateTag
```

Default `-RunTests` runs `git diff --check` and the repository-tool integration
suite. It does NOT run Flutter or certify compliance. For project checkpoints,
pass an explicit, reviewed `-TestCommands` array from a PowerShell session; record
the established toolchain, working directory, SQLite environment and full test
commands. Native failures stop each check immediately, including compound command
strings (PowerShell's native-error preference is enabled). Do not disable that
preference inside a check. Only those checks are represented in the manifest. Commands execute
locally as supplied: do not pass untrusted text or secrets. Logs are local output.

`-DryRun` validates without tests, output files or tags. Dirty worktrees fail by
default. `-AllowDirty` permits only an `UNVERIFIED_DIRTY` committed-HEAD bundle,
does not include dirty files, and cannot create a tag. A clean snapshot without
tests is `HISTORY_ONLY_TESTS_NOT_RUN`. `CHECKS_PASSED` means only the listed checks
passed on a clean tree, not a compliance/release approval. Do not run another
editor/agent changing the repository during a checkpoint.

Tags are lightweight `checkpoint/<name>` pointers, not signatures or approvals.
Existing names/output directories are never overwritten. On errors, partial
outputs/logs and any already-created tag remain for inspection; no destructive
rollback is attempted. A finalized manifest and matching hashes are required.

Output: `recovery/checkpoints/<name>/` with bundle, JSON manifest, readable
summary, SHA256SUMS and check logs. These payloads are ignored by Git. Evidence
hashes are working-copy byte hashes of selected files, not reconstructed evidence.
Bundles contain all reachable local refs plus HEAD, not reflogs, unreachable
objects, Git configuration, hooks, credentials, LFS payloads, submodule repositories,
dirty or ignored files. Preserve those separately when a future project uses them.

Shallow and partial/promisor clones are rejected: this workflow requires complete
history and must not silently download objects while checkpointing.

The validator reports local commits missing from cached origin across all branches, tracking
divergence, dirty state and current-HEAD checkpoint bundle hashes. It does not
claim live push status. `-RequireClean` and `-RequireCheckpoint` turn those gates
into failures. The checkpoint requirement proves a clean historical snapshot is
available, not that application tests were run; inspect `status` and test scope.

On a future machine, explicitly approve a new permanent path and pass
`-ExpectedPath <approved-path>` to both tools. Never use that override simply to
bypass a stale-workspace warning. It exists also for isolated integration tests.
Use the same GitHub repository and exact handoff SHA across machines.

## Restore without overwriting

1. Obtain the bundle plus manifest/hash through approved durable storage.
2. Compare SHA-256 against the independently recorded expected value.
3. In a fresh isolated location, `git clone --mirror <bundle> <new-path.git>` and
   `git -C <new-path.git> fsck --full`; verify the branch, full commit and parents.
4. Import only explicit reviewed refs into the canonical repository, using new
   `recovery/*` branch names if needed. Never reset or force-update current refs.
5. Review separate dirty-file backups/patches. A patch is not a preserved commit;
   require its base SHA and hashes, and create/verify a commit before handoff.
6. Run appropriate checks and report the result before integration.
