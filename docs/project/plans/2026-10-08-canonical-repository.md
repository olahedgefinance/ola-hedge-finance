# Canonical repository setup plan

Scope: repository governance and recoverability only. No application/compliance
remediation, lost-checkpoint reconstruction, push, branch deletion, or old-worktree cleanup.

1. Inventory old worktrees, refs, GitHub tips, dirty files and recovery reports.
2. Preserve all refs in a verified safety bundle and hash copied uncommitted files.
3. Clone the official repository into the permanent path. Preserve legacy branch
   pointers; leave main unchanged; create develop at main and a separate governance
   branch at the surviving `6a8a37668ce6b34761026e8594ae80a55ec2b851` baseline.
4. Write failing integration tests for canonical validation and checkpoint safety.
5. Implement validation/checkpoint scripts and governance/handoff documentation.
6. Verify refusal paths, real bundle restoration, checksums, all preserved source
   bytes and the app/compliance diff boundary. Do not rerun or claim app tests.
7. Commit only governance files locally using an explicitly identified author;
   create an independently restorable setup bundle. No push.
8. Produce the setup report with exact Git and preservation metadata. Keep the
   existing privacy document separate rather than silently merging its content.

Test gates: wrong path/origin, detached HEAD, dirty tree, unsafe/colliding names,
tag collision, failed checks, checks that alter the tree, dry-run no writes,
manifest hashes, local-only history restore, no automatic push, checkpoint tamper
detection. Generated test fixtures remain outside application working copies.
