# Repository execution gate

Before editing, read `docs/project/CANONICAL_REPOSITORY.md` and run
`pwsh -NoProfile -File scripts/verify_canonical_repo.ps1` from the canonical
repository. Record branch, full HEAD and working-tree status. Stop on a path or
origin failure; do not bypass it with `-ExpectedPath` without owner approval.

Canonical Windows path: `C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE`.
Official origin: `https://github.com/olahedgefinance/ola-hedge-finance`.

No push without explicit owner permission. No upstream push, history rewrite,
branch deletion or destructive cleanup. Preserve dirty work and create durable
commit/bundle handoff metadata before switching execution contexts. The historical
missing checkpoint is unavailable; never reconstruct it from reports.

The repository tools are governance only, not an application test or compliance
certification. Select and run task-appropriate tests; report exactly what ran.
