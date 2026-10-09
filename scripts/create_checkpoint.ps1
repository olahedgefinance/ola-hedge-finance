#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Name,
    [switch]$RunTests,
    [string[]]$TestCommands,
    [switch]$CreateTag,
    [switch]$AllowDirty,
    [switch]$DryRun,
    # Only override for an owner-approved machine path or isolated script tests.
    [string]$ExpectedPath = 'C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE'
)
. (Join-Path $PSScriptRoot 'repository_common.ps1')
try {
    if ($Name -cnotmatch '^[a-z0-9][a-z0-9._-]{0,79}$' -or $Name.Contains('..') -or $Name.EndsWith('.') -or
        $Name -match '^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.|$)') { throw 'Unsafe checkpoint name.' }
    $state = Get-CanonicalState -ExpectedPath $ExpectedPath
    if (!$state.Clean -and !$AllowDirty) { throw 'Dirty tree: commit/preserve edits first, or use -AllowDirty for an explicitly UNVERIFIED committed-HEAD snapshot.' }
    if (!$state.Clean -and $CreateTag) { throw 'Cannot create a checkpoint tag from a dirty tree, even with -AllowDirty.' }
    if ($TestCommands -and !$RunTests) { throw '-TestCommands requires -RunTests.' }
    if ($RunTests -and !$TestCommands) {
        $escapedTest = (Join-Path $PSScriptRoot 'tests/test_repository_tools.ps1').Replace("'", "''")
        $TestCommands = @('git diff --check', "& '$escapedTest'")
    }
    $destination = Join-Path $state.Path "recovery/checkpoints/$Name"
    Assert-NoReparsePoint $destination
    if (Test-Path -LiteralPath $destination) { throw "Checkpoint output already exists: $destination" }
    $tag = if ($CreateTag) { "checkpoint/$Name" } else { $null }
    if ($CreateTag) {
        Invoke-RepoGit @('check-ref-format', "refs/tags/$tag") | Out-Null
        if ((Invoke-RepoGit @('show-ref', '--verify', '--quiet', "refs/tags/$tag") -AllowFailure).ExitCode -eq 0) {
            throw "Tag already exists: $tag"
        }
    }
    # Output must be ignored before the operation; never hide an existing tracked file.
    $ignoreCheck = Invoke-RepoGit @('check-ignore', '--quiet', '--', "$destination/CHECKPOINT_MANIFEST.json") -AllowFailure
    if ($ignoreCheck.ExitCode -ne 0) { throw 'Checkpoint output is not ignored. Install the documented .gitignore rules first.' }
    if ($DryRun) {
        Write-Host "DRY RUN: $($state.Path) | $($state.Branch) | $($state.Head)"
        Write-Host "Would create $destination; RunTests=$RunTests; CreateTag=$CreateTag. No checks, files, refs, fetch or push performed."
        exit 0
    }
    New-Item -ItemType Directory -Path $destination | Out-Null
    $results = @()
    $engine = (Get-Process -Id $PID).Path
    if ($RunTests) {
        $index = 0
        Push-Location $state.Path
        try {
            foreach ($command in $TestCommands) {
                $index++
                $payload = "`$ErrorActionPreference='Stop'; `$PSNativeCommandUseErrorActionPreference=`$true; `$global:LASTEXITCODE=0; & { $command }; if (!`$?) { exit 1 }; exit `$LASTEXITCODE"
                $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
                $output = @(& $engine -NoProfile -EncodedCommand $encoded 2>&1 | ForEach-Object { "$_" })
                $exitCode = $LASTEXITCODE
                $log = "check-$index.log"
                Set-Content -LiteralPath (Join-Path $destination $log) -Value ($output -join "`n") -Encoding utf8
                $results += [pscustomobject]@{ command = $command; exitCode = $exitCode; log = $log }
                if ($exitCode -ne 0) { throw "Check failed ($exitCode); log retained: $destination/$log. No checkpoint tag created." }
            }
        } finally { Pop-Location }
    }
    $afterChecks = Get-CanonicalState -ExpectedPath $ExpectedPath
    if ($afterChecks.Head -ne $state.Head -or $afterChecks.Branch -ne $state.Branch -or
        ($afterChecks.Status -join "`n") -ne ($state.Status -join "`n")) { throw 'Checks changed repository identity or working-tree status; refusing checkpoint.' }
    if (!$afterChecks.Clean -and !$AllowDirty) { throw 'Checks left a dirty tree.' }
    $bundleName = "$Name.bundle"
    $bundle = Join-Path $destination $bundleName
    # Prove bundle creation before adding a requested local tag. Then recreate a
    # second bundle with the tag included. If a later IO failure occurs, retain
    # all output and the tag, report failure, and never force-delete evidence.
    Invoke-RepoGit @('bundle', 'create', $bundle, '--all', 'HEAD') | Out-Null
    Invoke-RepoGit @('bundle', 'verify', $bundle) | Out-Null
    if ($CreateTag) {
        Invoke-RepoGit @('tag', $tag, $state.Head) | Out-Null
        $taggedBundle = Join-Path $destination "$Name.tagged.bundle"
        Invoke-RepoGit @('bundle', 'create', $taggedBundle, '--all', 'HEAD') | Out-Null
        Invoke-RepoGit @('bundle', 'verify', $taggedBundle) | Out-Null
        # Only replace this invocation's newly generated intermediate bundle.
        Move-Item -LiteralPath $taggedBundle -Destination $bundle -Force
    }
    $end = Get-CanonicalState -ExpectedPath $ExpectedPath
    if ($end.Head -ne $state.Head -or $end.Branch -ne $state.Branch -or
        ($end.Status -join "`n") -ne ($state.Status -join "`n")) { throw 'Repository changed while bundling. Output retained; checkpoint not finalized.' }
    $hash = (Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash.ToLowerInvariant()
    $evidence = @(Get-EvidenceHashes $state.Path)
    $status = if (!$state.Clean) { 'UNVERIFIED_DIRTY' } elseif (!$RunTests) { 'HISTORY_ONLY_TESTS_NOT_RUN' } else { 'CHECKS_PASSED' }
    $manifest = [ordered]@{
        schemaVersion = 1; timestamp = [DateTimeOffset]::UtcNow.ToString('o')
        name = $Name; status = $status; verified = [bool]($state.Clean -and $RunTests)
        verificationScope = 'Git history transport and only the explicitly recorded checks; NOT product/compliance/release approval'
        repositoryUrl = $script:OfficialRepository; repositoryPath = $state.Path
        expectedPath = $ExpectedPath; branch = $state.Branch; head = $state.Head; tree = $state.Tree
        gitCommonDirectory = $state.GitCommonDirectory
        worktreeStatus = @($state.Status); worktreeClean = $state.Clean
        dirtyFilesIncludedInBundle = $false; ignoredFilesIncludedInBundle = $false
        historyScope = 'All locally reachable refs plus HEAD; no unreachable objects or uncommitted files'
        bundleFilename = $bundleName; bundleSha256 = $hash; tag = $tag
        refs = @((Invoke-RepoGit @('show-ref')).Lines)
        testCommands = @($TestCommands | Where-Object { $_ }); testResults = $results
        evidenceFiles = $evidence
        remotePushStatus = @{
            pushedByThisScript = $false; networkVerified = $false
            commitsNotInCachedOrigin = $state.CommitsNotInCachedOrigin
            allBranchCommitsNotInCachedOrigin = $state.AllBranchCommitsNotInCachedOrigin
            trackingBranch = $state.TrackingBranch; ahead = $state.Ahead; behind = $state.Behind
            note = 'Cached refs only. No fetch/push. Confirm live GitHub state separately before a pushed handoff.'
        }
    }
    $manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/CHECKPOINT_MANIFEST.json" -Encoding utf8
    @("# Checkpoint: $Name", '', "Status: $status", "Repository: $($state.Path)",
        "Branch: $($state.Branch)", "HEAD: $($state.Head)", "Tree: $($state.Tree)",
        "Bundle: $bundleName", "SHA-256: $hash", "Tag: $tag", '',
        'No push performed. Remote status uses cached refs only.',
        'Bundle includes committed, reachable Git history only. Dirty and ignored files are NOT preserved.',
        'CHECKS_PASSED is limited to the commands in the manifest; it is not compliance or release certification.',
        'Copy this directory to a separate durable location before switching environments.', '',
        "Checks: $($results.Count)", ($TestCommands -join "`n")) |
        Set-Content -LiteralPath "$destination/CHECKPOINT_SUMMARY.md" -Encoding utf8
    @("$hash  $bundleName") + @(foreach ($file in @('CHECKPOINT_MANIFEST.json', 'CHECKPOINT_SUMMARY.md') + @($results | ForEach-Object { $_.log })) {
        "$((Get-FileHash -LiteralPath (Join-Path $destination $file) -Algorithm SHA256).Hash.ToLowerInvariant())  $file"
    }) | Set-Content -LiteralPath "$destination/SHA256SUMS.txt" -Encoding utf8
    Write-Host "$status | $($state.Head) | $destination"
    Write-Host "Bundle SHA-256: $hash; no push performed."
    exit 0
} catch {
    Write-Error "Checkpoint FAILED: $_" -ErrorAction Continue
    exit 1
}
