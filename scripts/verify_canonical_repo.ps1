#requires -Version 7.4
[CmdletBinding()]
param(
    [string]$ExpectedPath = 'C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE',
    [switch]$AllowDetached,
    [switch]$RequireClean,
    [switch]$RequireCheckpoint
)
. (Join-Path $PSScriptRoot 'repository_common.ps1')
try {
    $state = Get-CanonicalState -ExpectedPath $ExpectedPath -AllowDetached:$AllowDetached
    Write-Host "PASS repository: $($state.Path)"
    Write-Host "PASS origin: $($state.Origin)"
    Write-Host "PASS HEAD: $($state.Head); branch: $($state.Branch)"
    Write-Host "PASS Git common directory: $($state.GitCommonDirectory)"
    if ($state.Clean) { Write-Host 'PASS worktree clean (ignored files excluded)' }
    elseif ($RequireClean) { throw "Dirty worktree: $($state.Status -join '; ')" }
    else { Write-Host "WARN dirty worktree: $($state.Status -join '; ')" }
    if ($state.TrackingBranch) {
        Write-Host "PASS cached tracking: $($state.TrackingBranch); ahead=$($state.Ahead); behind=$($state.Behind)"
        if ($state.Ahead -gt 0 -or $state.Behind -gt 0) { Write-Host 'WARN branch and cached upstream differ; reconcile explicitly before integration.' }
    } else { Write-Host 'WARN no upstream tracking branch configured.' }
    if ($state.CommitsNotInCachedOrigin -gt 0) { Write-Host "WARN $($state.CommitsNotInCachedOrigin) HEAD commits absent from cached origin refs; preserve in bundle or approved push." }
    if ($state.AllBranchCommitsNotInCachedOrigin -gt 0) { Write-Host "WARN $($state.AllBranchCommitsNotInCachedOrigin) local-branch commits absent from cached origin refs (all branches inspected)." }
    Write-Host 'WARN remote status is cached only; no fetch/push performed.'
    $checkpointRoot = Join-Path $state.Path 'recovery/checkpoints'
    $valid = 0
    if (Test-Path -LiteralPath $checkpointRoot) {
        Assert-NoReparsePoint $checkpointRoot
        foreach ($file in @(Get-ChildItem -LiteralPath $checkpointRoot -Filter CHECKPOINT_MANIFEST.json -Recurse -File)) {
            Assert-NoReparsePoint $file.FullName
            $manifest = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            $sumsPath = Join-Path $file.DirectoryName 'SHA256SUMS.txt'
            if (!(Test-Path -LiteralPath $sumsPath -PathType Leaf)) { throw "Incomplete checkpoint: missing $sumsPath" }
            Assert-NoReparsePoint $sumsPath
            $hashedNames = @()
            foreach ($line in @(Get-Content -LiteralPath $sumsPath)) {
                if ($line -notmatch '^([a-f0-9]{64})  ([a-zA-Z0-9][a-zA-Z0-9._-]*)$') { throw "Invalid checksum record in $sumsPath" }
                $expectedHash = $Matches[1]; $name = $Matches[2]
                if ($name.Contains('..') -or $hashedNames -contains $name) { throw "Unsafe/duplicate checksum name: $name" }
                $hashedNames += $name
                $artifact = Join-Path $file.DirectoryName $name
                Assert-NoReparsePoint $artifact
                if (!(Test-Path -LiteralPath $artifact -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash -ne $expectedHash) {
                    throw "Missing or changed checkpoint artifact: $artifact"
                }
            }
            foreach ($required in @('CHECKPOINT_MANIFEST.json', 'CHECKPOINT_SUMMARY.md', $manifest.bundleFilename) + @($manifest.testResults | ForEach-Object { $_.log })) {
                if ($hashedNames -notcontains $required) { throw "Checkpoint checksum record missing: $required" }
            }
            if ($manifest.bundleFilename -notmatch '^[a-z0-9][a-z0-9._-]*\.bundle$' -or $manifest.bundleFilename.Contains('..')) { throw "Unsafe bundle filename in $($file.FullName)" }
            $bundle = Join-Path $file.DirectoryName $manifest.bundleFilename
            Assert-NoReparsePoint $bundle
            if (!(Test-Path -LiteralPath $bundle -PathType Leaf)) { throw "Missing checkpoint bundle: $bundle" }
            if ((Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash -ne $manifest.bundleSha256) { throw "Checkpoint bundle checksum mismatch: $bundle" }
            Invoke-RepoGit @('bundle', 'verify', $bundle) | Out-Null
            $bundleHeads = (Invoke-RepoGit @('bundle', 'list-heads', $bundle)).Lines
            if ($bundleHeads -notcontains "$($manifest.head) refs/heads/$($manifest.branch)") {
                throw "Manifest branch/HEAD not advertised by bundle: $bundle"
            }
            if ($manifest.head -eq $state.Head -and $manifest.worktreeClean -and $manifest.repositoryUrl -eq $script:OfficialRepository) {
                $valid++
                Write-Host "PASS current-HEAD bundle/hash: $($file.DirectoryName); scope=$($manifest.status)"
            } else { Write-Host "WARN historical/unverified checkpoint: $($file.DirectoryName)" }
        }
    }
    if ($valid -eq 0) {
        if ($RequireCheckpoint) { throw 'No intact clean-worktree checkpoint for current HEAD.' }
        Write-Host 'WARN no intact clean-worktree checkpoint for current HEAD.'
    }
    Write-Host 'PASS required canonical checks; review WARN items before handoff.'
    exit 0
} catch {
    Write-Host "FAIL $_"
    exit 1
}
