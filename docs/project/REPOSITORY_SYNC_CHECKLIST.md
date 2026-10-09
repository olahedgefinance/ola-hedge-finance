# Repository sync checklist

## Before starting Codex work

- Open the canonical folder; run `scripts/verify_canonical_repo.ps1` in PowerShell 7.4+.
- Inspect `git status --short --untracked-files=all`; preserve any existing edits.
- Record `git branch --show-current` and `git rev-parse HEAD` (full SHA).
- Fetch origin (read-only remote operation, local tracking refs update) when
  authorized/online: `git -c gc.auto=0 fetch --no-prune origin`. Never auto-pull.
- Compare local and remote tips; inspect `git branch -vv` and, when an upstream
  exists, `git rev-list --left-right --count 'HEAD...@{upstream}'`.
- Verify the starting SHA matches the handoff, not merely a branch name.
- Create an appropriate feature/fix/compliance/release task branch if needed.
  Do not rewrite or discard an existing branch to match a stale handoff.

## Before switching to Work (or Personal/Business/cloud/machine)

- Run relevant checks; record commands, results, failures and unrun tests.
- Review diff and commit meaningful authorized work; retain unrelated edits.
- Record branch, full HEAD, parent SHA(s), changed files and working-tree status.
- Push only with explicit approval, then verify the exact remote SHA; or create
  and verify a bundle. Important release/compliance checkpoints should have both.
- Independently preserve dirty/untracked/necessary ignored files with hashes.
- Copy local bundles to approved off-machine storage and confirm accessibility
  from the destination. A bundle path on an inaccessible Windows disk is not a
  completed cloud handoff.
- Fill `CODEX_TO_WORK_HANDOFF.md`; provide repo/branch/SHA and bundle/hash if needed.

## Before switching back to Codex

- Obtain the completed `WORK_TO_CODEX_HANDOFF.md`, result branch/SHA and parents.
- Verify whether that exact commit is on GitHub. Do not trust “pushed” prose alone.
- If not pushed, verify supplied bundle hashes and restore into a fresh isolated
  repository. A patch alone does not preserve commit identity; request a bundle
  when Work claims committed changes. Preserve patches with their base SHA too.
- Verify parents and review changed files/evidence; import only explicit refs,
  without overwriting active branches or merging automatically.
- Run appropriate tests in the canonical working copy after approved integration.
- Continue only when actual Git state matches the recorded handoff.

## Always

- Notion is status, Git is source truth. Never rebuild a lost verified checkpoint
  from prose, counts or exports.
- No force-push, upstream push, unapproved push, branch deletion, destructive
  checkout/reset, clean, prune or GC as part of this workflow.
- Each execution context begins at a known branch/SHA and ends with commit and
  preservation metadata, or explicitly reports that work is not yet preserved.
