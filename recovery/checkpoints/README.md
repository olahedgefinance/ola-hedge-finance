# Local checkpoints

Run `scripts/create_checkpoint.ps1` from the canonical repository using PowerShell
7.4+ and Git on PATH. Generated subdirectories are ignored; bundles must not enter
normal source history. Copy them to separate owner-approved durable storage and
record their hashes. Never put secrets in test commands or committed manifests.

See `docs/project/CANONICAL_REPOSITORY.md` for scope, checks and safe restore.
