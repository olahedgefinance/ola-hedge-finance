#requires -Version 7.4
# Shared, read-only checks. These tools never fetch or push.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Git probing intentionally handles nonzero exits (missing refs/config) below.
# User-supplied checks run in a separate fail-fast PowerShell process.
$PSNativeCommandUseErrorActionPreference = $false
$script:OfficialRepository = 'https://github.com/olahedgefinance/ola-hedge-finance'
$script:CanonicalPath = 'C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE'
$script:GitExecutable = (Get-Command git -ErrorAction Stop).Source
function Invoke-RepoGit {
    param([string[]]$Arguments, [switch]$AllowFailure)
    $output = @(& $script:GitExecutable -c gc.auto=0 @Arguments 2>&1 | ForEach-Object { "$_" })
    $code = $LASTEXITCODE
    if ($code -ne 0 -and !$AllowFailure) { throw "git $($Arguments -join ' ') failed ($code): $($output -join ' ')" }
    [pscustomobject]@{ ExitCode = $code; Text = ($output -join "`n"); Lines = $output }
}
function Get-CanonicalState {
    param([string]$ExpectedPath, [switch]$AllowDetached)
    $root = (Invoke-RepoGit @('rev-parse', '--show-toplevel')).Text
    $actual = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
    $expected = [IO.Path]::GetFullPath($ExpectedPath).TrimEnd('\', '/')
    if (![string]::Equals($actual, $expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Not the canonical repository: actual '$actual', expected '$expected'."
    }
    $origin = (Invoke-RepoGit @('remote', 'get-url', 'origin')).Text.TrimEnd('/')
    if ($origin -notin @($script:OfficialRepository, "$script:OfficialRepository.git", 'git@github.com:olahedgefinance/ola-hedge-finance.git')) {
        throw "Unexpected origin: $origin"
    }
    if ((Invoke-RepoGit @('rev-parse', '--is-shallow-repository')).Text -eq 'true') {
        throw 'Shallow history cannot serve as the canonical full-history repository.'
    }
    $promisor = Invoke-RepoGit @('config', '--get-regexp', '^remote\..*\.promisor$') -AllowFailure
    $partial = Invoke-RepoGit @('config', '--get', 'extensions.partialClone') -AllowFailure
    if ($promisor.ExitCode -eq 0 -or $partial.ExitCode -eq 0) {
        throw 'Partial/promisor clone is not supported: use a complete clone, without automatic lazy fetch.'
    }
    $head = (Invoke-RepoGit @('rev-parse', '--verify', 'HEAD^{commit}')).Text
    $branchResult = Invoke-RepoGit @('symbolic-ref', '--quiet', '--short', 'HEAD') -AllowFailure
    if ($branchResult.ExitCode -ne 0 -and !$AllowDetached) { throw 'Detached HEAD is not permitted.' }
    $branch = if ($branchResult.ExitCode -eq 0) { $branchResult.Text } else { $null }
    $status = (Invoke-RepoGit @('status', '--porcelain=v1', '--untracked-files=all')).Lines
    $tracking = Invoke-RepoGit @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}') -AllowFailure
    $ahead = $null; $behind = $null
    if ($tracking.ExitCode -eq 0) {
        $counts = (Invoke-RepoGit @('rev-list', '--left-right', '--count', 'HEAD...@{upstream}')).Text -split '\s+'
        $ahead = [int]$counts[0]; $behind = [int]$counts[1]
    }
    $localOnly = [int](Invoke-RepoGit @('rev-list', '--count', 'HEAD', '--not', '--remotes=origin')).Text
    [pscustomobject]@{
        Path = $actual; Origin = $origin; Branch = $branch; Head = $head
        Tree = (Invoke-RepoGit @('rev-parse', 'HEAD^{tree}')).Text
        Status = @($status); Clean = ($status.Count -eq 0)
        TrackingBranch = $(if ($tracking.ExitCode -eq 0) { $tracking.Text } else { $null })
        Ahead = $ahead; Behind = $behind; CommitsNotInCachedOrigin = $localOnly
        AllBranchCommitsNotInCachedOrigin = [int](Invoke-RepoGit @('rev-list', '--count', '--branches', '--not', '--remotes=origin')).Text
        GitCommonDirectory = (Invoke-RepoGit @('rev-parse', '--path-format=absolute', '--git-common-dir')).Text
    }
}
function Assert-NoReparsePoint {
    param([string]$Path)
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -Force -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse point is not allowed for checkpoint storage: $cursor"
            }
        }
        $cursor = Split-Path $cursor -Parent
    }
}
function Get-EvidenceHashes {
    param([string]$Root)
    $selected = @('THIRD_PARTY_NOTICES.md', 'budget/THIRD_PARTY_NOTICES.md', 'legal/THIRD_PARTY_NOTICES.md',
        'compliance/sbom/current.spdx.json', 'compliance/release/release-manifest.template.json',
        'budget/brand/brand_manifest.json', 'LICENSE')
    foreach ($relative in $selected) {
        $path = Join-Path $Root $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            [pscustomobject]@{ path = $relative; sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
        }
    }
}
