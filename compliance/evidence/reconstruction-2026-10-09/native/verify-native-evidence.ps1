param([string]$EvidenceDirectory=$PSScriptRoot)
$ErrorActionPreference='Stop'
$manifest=Get-Content -Raw -LiteralPath (Join-Path $EvidenceDirectory 'native-wrapper-cache-inventory.json') | ConvertFrom-Json
$downloads=@(Get-Content -Raw -LiteralPath (Join-Path $EvidenceDirectory 'hosted-archive-authentication.json') | ConvertFrom-Json)
if ($manifest.mappings.Count -ne 25 -or $downloads.Count -ne 24) { throw 'Unexpected inventory size' }
foreach ($file in $manifest.files) {
  if ($file.path -match '(^[/\\]|^[A-Za-z]:|(^|[/\\])\.\.([/\\]|$))') { throw 'Unsafe evidence path' }
  $actual=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $EvidenceDirectory $file.path)).Hash.ToLowerInvariant()
  if ($actual -ne $file.sha256) { throw "Evidence hash mismatch: $($file.path)" }
}
foreach ($row in $manifest.mappings) {
  if (!$row.pubspec_identity_matches_lock -or !$row.static_pod_version_matches_lock) { throw "Identity/static-version mismatch: $($row.package)" }
  if ($row.spec_checksum_verified -or $row.cocoapods_evaluated) { throw 'Unsubstantiated CocoaPods verification flag' }
  if ($row.source_kind -eq 'hosted') {
    $download=@($downloads | Where-Object package -eq $row.package)
    if ($download.Count -ne 1 -or !$download[0].hash_matches -or $download[0].actual_sha256 -ne $row.locked_archive_sha256) { throw "Archive hash evidence mismatch: $($row.package)" }
    if (!$row.archive_bytes_rehashed -or !$row.extracted_cache_authenticated_against_archive) { throw 'Missing retained-file authentication' }
    foreach ($comparison in $row.retained_file_archive_comparisons) {
      $file=@($manifest.files | Where-Object path -eq $comparison.evidence_path)
      if ($file.Count -ne 1 -or !$comparison.matches -or $comparison.archive_member_sha256 -ne $file[0].sha256) { throw "Archive-member comparison mismatch: $($comparison.evidence_path)" }
    }
  }
}
$git=Get-Content -Raw -LiteralPath (Join-Path $EvidenceDirectory 'file-picker-git-identity.json') | ConvertFrom-Json
$gitrow=$manifest.mappings | Where-Object package -eq 'file_picker'
if ($git.observed_head -ne $gitrow.locked_git_revision -or $git.observed_status_porcelain -ne '') { throw 'Git identity evidence mismatch' }
"PASS $($manifest.files.Count) retained evidence file hashes; 25 identity/static-version records; 24 archive-authentication records; exact clean file_picker Git identity record."
'LIMIT: Offline evidence integrity verification only. No fresh archive download, Git source recheck, CocoaPods replay, native build or licensing clearance.'
