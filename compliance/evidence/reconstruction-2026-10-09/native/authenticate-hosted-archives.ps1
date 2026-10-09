param([string]$EvidenceDirectory=$PSScriptRoot, [string]$ArchiveDirectory=(Join-Path (Split-Path $PSScriptRoot) 'native-archives'))
$ErrorActionPreference='Stop'
$manifestPath=Join-Path $EvidenceDirectory 'native-wrapper-cache-inventory.json'
$manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $ArchiveDirectory | Out-Null
$hosted=@($manifest.mappings | Where-Object source_kind -eq 'hosted')
$downloads=@($hosted | ForEach-Object -Parallel {
  $row=$_
  $archiveRoot=$using:ArchiveDirectory
  $name="$($row.package)-$($row.locked_pub_version).tar.gz"
  $path=Join-Path $archiveRoot $name
  $url="https://pub.dev/api/archives/$name"
  try {
    Invoke-WebRequest -Uri $url -OutFile $path -TimeoutSec 120
    $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{package=$row.package; archive_filename=$name; download_url=$url; expected_sha256=$row.locked_archive_sha256; actual_sha256=$hash; hash_matches=($hash -eq $row.locked_archive_sha256); bytes=(Get-Item -LiteralPath $path).Length; error=$null}
  } catch { [pscustomobject]@{package=$row.package;archive_filename=$name;download_url=$url;expected_sha256=$row.locked_archive_sha256;actual_sha256=$null;hash_matches=$false;bytes=0;error=$_.Exception.Message} }
} -ThrottleLimit 4)
$downloads | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'hosted-archive-authentication.json') -Encoding utf8
foreach ($download in $downloads) {
  $row=$manifest.mappings | Where-Object package -eq $download.package
  $comparisons=[System.Collections.Generic.List[object]]::new()
  if ($download.hash_matches) {
    $archive=Join-Path $ArchiveDirectory $download.archive_filename
    $extracted=Join-Path $ArchiveDirectory "$($download.package)-extracted"
    New-Item -ItemType Directory -Force -Path $extracted | Out-Null
    $members=@(& tar -tzf $archive)
    if ($LASTEXITCODE -ne 0) { throw "Archive listing failed: $archive" }
    foreach ($member in $members) { if ($member -match '(^[/\\]|^[A-Za-z]:|(^|[/\\])\.\.([/\\]|$))') { throw "Unsafe archive member: $member" } }
    & tar -xzf $archive -C $extracted
    if ($LASTEXITCODE -ne 0) { throw "Archive extraction failed: $archive" }
    $prefix="packages/$($download.package)/"
    foreach ($file in @($manifest.files | Where-Object { $_.path.StartsWith($prefix) -and !$_.path.EndsWith('cache-archive.sha256') })) {
      $relative=$file.path.Substring($prefix.Length)
      $upstream=Join-Path $extracted $relative
      $actual=if(Test-Path -LiteralPath $upstream -PathType Leaf){(Get-FileHash -LiteralPath $upstream -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}
      $comparisons.Add([ordered]@{evidence_path=$file.path;archive_member=$relative;expected_sha256=$file.sha256;archive_member_sha256=$actual;matches=($actual -eq $file.sha256)})
    }
  }
  $row.archive_bytes_rehashed=[bool]$download.hash_matches
  $row.extracted_cache_authenticated_against_archive=($download.hash_matches -and $comparisons.Count -gt 0 -and @($comparisons | Where-Object { !$_.matches }).Count -eq 0)
  $row | Add-Member -NotePropertyName authenticated_archive_filename -NotePropertyValue $download.archive_filename -Force
  $row | Add-Member -NotePropertyName authenticated_archive_download_url -NotePropertyValue $download.download_url -Force
  $row | Add-Member -NotePropertyName retained_file_archive_comparisons -NotePropertyValue @($comparisons.ToArray()) -Force
  if ($row.extracted_cache_authenticated_against_archive) { $row.status='AUTHENTICATED_PUB_ARCHIVE_RETAINED_FILES_PODSPEC_CHECKSUM_UNVERIFIED' }
}
$manifest.caveats=@('24 hosted archive authentication results are recorded per mapping; only matching retained file bytes are authenticated.', 'Archives are retained externally by filename and SHA256, not included as repository binaries.', 'Podspecs are statically inspected only; no CocoaPods checksum replay has run.', 'Git cache revision is independently recorded in file-picker-git-identity.json.', 'Wrapper licenses do not clear native SDK or transitive licensing obligations.')
$manifest | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$downloads | ForEach-Object { "$($_.package): hash_matches=$($_.hash_matches); error=$($_.error)" }
"Authenticated retained file sets: $(@($manifest.mappings | Where-Object extracted_cache_authenticated_against_archive).Count)/24"
