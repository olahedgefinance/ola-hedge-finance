#requires -Version 7.4
[CmdletBinding()]
param([string]$CaseFilter = '*')
$ErrorActionPreference = 'Stop'
# Negative-path tests deliberately inspect nonzero subprocess exits themselves.
$PSNativeCommandUseErrorActionPreference = $false
$source = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$checkpoint = Join-Path $source 'scripts/create_checkpoint.ps1'
$validator = Join-Path $source 'scripts/verify_canonical_repo.ps1'
if (!(Test-Path $checkpoint) -or !(Test-Path $validator)) {
    throw 'RED: repository tools have not been implemented.'
}
$engine = (Get-Process -Id $PID).Path
$git = (Get-Command git -ErrorAction Stop).Source
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('ola-repository-tools-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$script:passes = 0
function Assert($condition, [string]$message) { if (!$condition) { throw $message } }
function Git([string[]]$Arguments) {
    $output = & $git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($output -join "`n") }
    return ($output -join "`n")
}
function Fixture([string]$name) {
    $repo = Join-Path $testRoot $name
    Git @('init', '-b', 'main', $repo) | Out-Null
    Git @('-C', $repo, 'config', 'user.name', 'Repository tool test') | Out-Null
    Git @('-C', $repo, 'config', 'user.email', 'test@example.invalid') | Out-Null
    Git @('-C', $repo, 'config', 'core.autocrlf', 'false') | Out-Null
    Git @('-C', $repo, 'config', 'gc.auto', '0') | Out-Null
    Git @('-C', $repo, 'remote', 'add', 'origin', 'https://github.com/olahedgefinance/ola-hedge-finance') | Out-Null
    Set-Content (Join-Path $repo '.gitignore') '/recovery/checkpoints/'
    Set-Content (Join-Path $repo 'LICENSE') 'fixture only'
    Git @('-C', $repo, 'add', '.') | Out-Null
    Git @('-C', $repo, 'commit', '-m', 'fixture baseline') | Out-Null
    Git @('-C', $repo, 'update-ref', 'refs/remotes/origin/main', 'HEAD') | Out-Null
    Git @('-C', $repo, 'branch', '--set-upstream-to=origin/main') | Out-Null
    return $repo
}
function Run([string]$repo, [string]$scriptFile, [string[]]$arguments) {
    Push-Location $repo
    try {
        $output = & $engine -NoProfile -File $scriptFile @arguments 2>&1
        return @{ Code = $LASTEXITCODE; Output = ($output -join "`n") }
    } finally { Pop-Location }
}
function Case([string]$name, [scriptblock]$body) {
    if ($name -notlike $CaseFilter) { return }
    & $body
    $script:passes++
    Write-Host "PASS $name"
}

Case 'canonical path mismatch refuses without writing' {
    $r = Fixture 'wrong-path'
    $result = Run $r $checkpoint @('-Name', 'refused')
    Assert ($result.Code -ne 0) 'Wrong path accepted'
    Assert (!(Test-Path "$r/recovery")) 'Refusal wrote checkpoint files'
    Assert ((Run $r $validator @()).Code -ne 0) 'Validator accepted wrong path'
}
Case 'clean fixture validation and missing checkpoint gate' {
    $r = Fixture 'validation'
    Assert ((Run $r $validator @('-ExpectedPath', $r)).Code -eq 0) 'Clean validation failed'
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireCheckpoint')).Code -ne 0) 'Missing checkpoint accepted'
}
Case 'wrong origin refused by both tools' {
    $r = Fixture 'wrong-origin'
    Git @('-C', $r, 'remote', 'set-url', 'origin', 'https://example.invalid/wrong') | Out-Null
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'refused')).Code -ne 0) 'Wrong origin accepted'
    Assert ((Run $r $validator @('-ExpectedPath', $r)).Code -ne 0) 'Validator accepted wrong origin'
}
Case 'detached HEAD requires explicit validator allowance and cannot checkpoint' {
    $r = Fixture 'detached'
    Git @('-C', $r, 'switch', '--detach') | Out-Null
    Assert ((Run $r $validator @('-ExpectedPath', $r)).Code -ne 0) 'Detached HEAD accepted'
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-AllowDetached')).Code -eq 0) 'Explicit detached validation failed'
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'refused')).Code -ne 0) 'Detached checkpoint accepted'
}
Case 'dirty tree refused and never tagged' {
    $r = Fixture 'dirty'
    Set-Content "$r/untracked.txt" 'important unpublished work'
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'dirty', '-CreateTag')
    Assert ($result.Code -ne 0) 'Dirty tree accepted'
    Assert ((Git @('-C', $r, 'tag', '-l')) -eq '') 'Failure created tag'
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireClean')).Code -ne 0) 'Dirty required-clean validation passed'
}
Case 'dirty override is explicitly unverified and preserves original bytes' {
    $r = Fixture 'dirty-override'
    Set-Content "$r/untracked.txt" 'important unpublished work'
    $before = (Get-FileHash "$r/untracked.txt").Hash
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'dirty', '-AllowDirty')
    Assert ($result.Code -eq 0) $result.Output
    $m = Get-Content -Raw "$r/recovery/checkpoints/dirty/CHECKPOINT_MANIFEST.json" | ConvertFrom-Json
    Assert (!$m.verified -and $m.status -eq 'UNVERIFIED_DIRTY') 'Dirty override misrepresented'
    Assert ($m.dirtyFilesIncludedInBundle -eq $false) 'Bundle falsely includes working edits'
    Assert ((Get-FileHash "$r/untracked.txt").Hash -eq $before) 'Dirty file changed'
}
Case 'unsafe checkpoint names refused' {
    $r = Fixture 'unsafe-names'
    foreach ($name in @('../escape', 'CON', 'bad/name', 'bad..name', 'trailing.')) {
        Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', $name)).Code -ne 0) "Unsafe name accepted: $name"
    }
}
Case 'dry run changes neither files nor refs' {
    $r = Fixture 'dry-run'
    $before = Git @('-C', $r, 'show-ref')
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'preview', '-DryRun', '-RunTests', '-CreateTag')
    Assert ($result.Code -eq 0) $result.Output
    Assert (!(Test-Path "$r/recovery")) 'Dry run wrote output'
    Assert ((Git @('-C', $r, 'show-ref')) -eq $before) 'Dry run changed refs'
}
Case 'failing checks cannot create successful checkpoint or tag' {
    $r = Fixture 'failing-check'
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'failed', '-RunTests', '-TestCommands', 'exit 7', '-CreateTag')
    Assert ($result.Code -ne 0) 'Failing check accepted'
    Assert ((Git @('-C', $r, 'tag', '-l')) -eq '') 'Failing check created tag'
    Assert (!(Test-Path "$r/recovery/checkpoints/failed/CHECKPOINT_MANIFEST.json")) 'Failed check created success manifest'
}
Case 'checks that dirty the repository abort checkpoint' {
    $r = Fixture 'mutating-check'
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'mutated', '-RunTests', '-TestCommands', "Set-Content 'LICENSE' 'changed'", '-CreateTag')
    Assert ($result.Code -ne 0) 'Mutating checks accepted'
    Assert ((Git @('-C', $r, 'tag', '-l')) -eq '') 'Mutating check created tag'
}
Case 'compound checks stop at first native failure' {
    $r = Fixture 'compound-failure'
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'failed', '-RunTests', '-TestCommands', 'git rev-parse --verify missing-checkpoint-test-ref; git --version', '-CreateTag')
    Assert ($result.Code -ne 0) 'Later successful native command masked a failed check'
    Assert ((Git @('-C', $r, 'tag', '-l')) -eq '') 'Failed compound check created tag'
    Assert (!(Test-Path "$r/recovery/checkpoints/failed/CHECKPOINT_MANIFEST.json")) 'Failed compound check created manifest'
}
Case 'bundle preserves local-only branches, full history, evidence hashes; never pushes' {
    $r = Fixture 'restore'
    Git @('-C', $r, 'switch', '-c', 'feature/local-only') | Out-Null
    Set-Content "$r/THIRD_PARTY_NOTICES.md" 'fixture evidence'
    Git @('-C', $r, 'add', '.') | Out-Null
    Git @('-C', $r, 'commit', '-m', 'local-only evidence') | Out-Null
    $head = Git @('-C', $r, 'rev-parse', 'HEAD')
    $remoteRefs = Git @('-C', $r, 'for-each-ref', 'refs/remotes')
    # A push would fail; no service/network is needed for these tests.
    Git @('-C', $r, 'remote', 'set-url', '--push', 'origin', 'https://example.invalid/NO_PUSH') | Out-Null
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'good', '-RunTests', '-TestCommands', 'git diff --check', '-CreateTag')
    Assert ($result.Code -eq 0) $result.Output
    $dir = "$r/recovery/checkpoints/good"
    $m = Get-Content -Raw "$dir/CHECKPOINT_MANIFEST.json" | ConvertFrom-Json
    Assert ($m.head -eq $head -and $m.verified) 'Manifest identity/checks incorrect'
    Assert ($m.bundleSha256 -eq (Get-FileHash "$dir/good.bundle").Hash.ToLowerInvariant()) 'Bundle hash mismatch'
    Assert ($m.evidenceFiles[0].sha256 -eq (Get-FileHash "$r/THIRD_PARTY_NOTICES.md").Hash.ToLowerInvariant()) 'Evidence hash mismatch'
    Assert ($m.testResults[0].exitCode -eq 0) 'Missing check result'
    Assert (Test-Path "$dir/check-1.log") 'Successful quiet check did not create its log'
    Assert ($m.remotePushStatus.pushedByThisScript -eq $false) 'Incorrect push status'
    Assert ((Git @('-C', $r, 'for-each-ref', 'refs/remotes')) -eq $remoteRefs) 'Remote refs mutated'
    Assert ((Git @('-C', $r, 'status', '--porcelain')) -eq '') 'Checkpoint dirtied worktree'
    Git @('clone', '--mirror', "$dir/good.bundle", "$testRoot/restored.git") | Out-Null
    Git @('-C', "$testRoot/restored.git", 'fsck', '--full') | Out-Null
    Assert ((Git @('-C', "$testRoot/restored.git", 'rev-parse', 'feature/local-only')) -eq $head) 'Local-only branch not restored'
    Assert ((Git @('-C', "$testRoot/restored.git", 'rev-parse', 'checkpoint/good')) -eq $head) 'Tag not restored'
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireCheckpoint', '-RequireClean')).Code -eq 0) 'Valid checkpoint rejected'
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'good')).Code -ne 0) 'Existing output overwritten'
    Add-Content "$dir/good.bundle" 'tamper'
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireCheckpoint')).Code -ne 0) 'Tampered checkpoint accepted'
}
Case 'existing tag is never overwritten' {
    $r = Fixture 'tag-collision'
    Git @('-C', $r, 'tag', 'checkpoint/existing') | Out-Null
    $refs = Git @('-C', $r, 'show-ref')
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'existing', '-CreateTag')).Code -ne 0) 'Existing tag accepted'
    Assert ((Git @('-C', $r, 'show-ref')) -eq $refs) 'Existing tag mutated'
}
Case 'incomplete or tampered metadata cannot satisfy checkpoint gate' {
    $r = Fixture 'metadata'
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'meta')).Code -eq 0) 'Checkpoint failed'
    $dir = "$r/recovery/checkpoints/meta"
    Move-Item "$dir/SHA256SUMS.txt" "$dir/sums.saved"
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireCheckpoint')).Code -ne 0) 'Incomplete checkpoint accepted'
    Move-Item "$dir/sums.saved" "$dir/SHA256SUMS.txt"
    Add-Content "$dir/CHECKPOINT_MANIFEST.json" ' '
    Assert ((Run $r $validator @('-ExpectedPath', $r, '-RequireCheckpoint')).Code -ne 0) 'Tampered manifest accepted'
}
Case 'no-test snapshot is not called verified' {
    $r = Fixture 'history-only'
    $result = Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'history')
    Assert ($result.Code -eq 0) $result.Output
    $m = Get-Content -Raw "$r/recovery/checkpoints/history/CHECKPOINT_MANIFEST.json" | ConvertFrom-Json
    Assert (!$m.verified -and $m.status -eq 'HISTORY_ONLY_TESTS_NOT_RUN') 'Unrun tests called verified'
}
Case 'validator warns about local-only commits on another branch' {
    $r = Fixture 'other-branch'
    Git @('-C', $r, 'switch', '-c', 'feature/unpublished') | Out-Null
    Set-Content "$r/local.txt" 'unpublished'
    Git @('-C', $r, 'add', '.') | Out-Null
    Git @('-C', $r, 'commit', '-m', 'unpublished') | Out-Null
    Git @('-C', $r, 'switch', 'main') | Out-Null
    $result = Run $r $validator @('-ExpectedPath', $r)
    Assert ($result.Code -eq 0) $result.Output
    Assert ($result.Output -match '1 local-branch commits absent') 'Non-current unpushed branch was overlooked'
}
Case 'shallow or partial checkout cannot claim full-history preservation' {
    $baseRepo = Fixture 'shallow-source'
    $r = Join-Path $testRoot 'shallow-clone'
    $uri = ([uri]$baseRepo).AbsoluteUri
    Git @('clone', '--depth=1', $uri, $r) | Out-Null
    Git @('-C', $r, 'remote', 'set-url', 'origin', 'https://github.com/olahedgefinance/ola-hedge-finance') | Out-Null
    Assert ((Run $r $checkpoint @('-ExpectedPath', $r, '-Name', 'incomplete')).Code -ne 0) 'Shallow history accepted'
    Assert ((Run $r $validator @('-ExpectedPath', $r)).Code -ne 0) 'Shallow canonical repository accepted'
    Git @('-C', $baseRepo, 'config', 'remote.origin.promisor', 'true') | Out-Null
    Assert ((Run $baseRepo $checkpoint @('-ExpectedPath', $baseRepo, '-Name', 'partial')).Code -ne 0) 'Partial clone accepted'
    Assert ((Run $baseRepo $validator @('-ExpectedPath', $baseRepo)).Code -ne 0) 'Partial canonical repository accepted'
}
Write-Host "$script:passes cases passed; 0 failed. Fixtures retained: $testRoot"
