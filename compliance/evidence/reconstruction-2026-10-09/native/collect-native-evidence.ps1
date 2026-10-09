$ErrorActionPreference = 'Stop'
$canonical = 'C:\Users\Oluwa\Documents\Codex\OLA-HEDGE-FINANCE'
$cache = 'C:\Users\Oluwa\Documents\Codex\2026-09-18\you-are-working-on-a-fork\work\pub-cache'
$output = $PSScriptRoot
$pubLock = Get-Content -Raw -LiteralPath "$canonical\budget\pubspec.lock"
$podLock = Get-Content -Raw -LiteralPath "$canonical\budget\ios\Podfile.lock"
$names = 'app_links app_settings cloud_firestore device_info_plus file_picker firebase_auth firebase_core flutter_charset_detector_ios flutter_local_notifications flutter_timezone google_sign_in_ios home_widget image_picker_ios in_app_purchase_storekit in_app_review local_auth_darwin package_info_plus path_provider_foundation quick_actions_ios recaptcha_enterprise_flutter share_plus shared_preferences_foundation sqlite3_flutter_libs system_theme url_launcher_ios' -split ' '
$files = [System.Collections.Generic.List[object]]::new()
function Save-Evidence([string]$source, [string]$relative) {
  $target = Join-Path $output $relative
  New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
  Copy-Item -LiteralPath $source -Destination $target
  $a = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant()
  $b = (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash.ToLowerInvariant()
  if ($a -ne $b) { throw "Copy hash mismatch: $source" }
  $files.Add([ordered]@{path=$relative; sha256=$a; source=$source; bytes=(Get-Item -LiteralPath $source).Length})
}
Save-Evidence "$canonical\budget\pubspec.lock" 'inputs/pubspec.lock'
Save-Evidence "$canonical\budget\ios\Podfile.lock" 'inputs/Podfile.lock'
$rows = foreach ($name in $names) {
  $block = [regex]::Match($pubLock, '(?ms)^  '+[regex]::Escape($name)+':\r?\n(.*?)(?=^  \S|^sdks:|\z)').Groups[1].Value
  if (!$block) { throw "Missing lock entry $name" }
  $version = [regex]::Match($block,'(?m)^    version: "([^"]+)"').Groups[1].Value
  $sourceKind = [regex]::Match($block,'(?m)^    source: (\S+)').Groups[1].Value
  $archiveHash = [regex]::Match($block,'(?m)^      sha256: "?([a-f0-9]{64})').Groups[1].Value
  $revision = [regex]::Match($block,'(?m)^      resolved-ref: (\S+)').Groups[1].Value
  $downloadIdentity = [regex]::Match($block,'(?m)^      url: "?([^"\r\n]+)').Groups[1].Value
  if ($sourceKind -eq 'hosted') { $package = "$cache\hosted\pub.dev\$name-$version" }
  elseif ($name -eq 'file_picker') { $package = "$cache\git\flutter_file_picker-$revision" }
  else { throw "Unsupported source $name $sourceKind" }
  $pubspecPath = Join-Path $package 'pubspec.yaml'
  $pubspec = Get-Content -Raw -LiteralPath $pubspecPath
  $actualName = [regex]::Match($pubspec,'(?m)^name:\s*["'']?([^\s"'']+)').Groups[1].Value
  $actualVersion = [regex]::Match($pubspec,'(?m)^version:\s*["'']?([^\s"'']+)').Groups[1].Value
  $externalPath = [regex]::Match($podLock,'(?m)^  '+[regex]::Escape($name)+':\r?\n    :path: "([^"]+)"').Groups[1].Value
  $platformDirectory = ($externalPath -split '/')[-1]
  $podspecPath = Join-Path $package "$platformDirectory/$name.podspec"
  $podspec = Get-Content -Raw -LiteralPath $podspecPath
  $versionExpression = [regex]::Match($podspec,'(?m)^\s*\w+\.version\s*=\s*([^\r\n]+)').Groups[1].Value.Trim()
  $nameExpression = [regex]::Match($podspec,'(?m)^\s*\w+\.name\s*=\s*([^\r\n]+)').Groups[1].Value.Trim()
  $literal = [regex]::Match($versionExpression,'^["'']([^"'']+)["'']$')
  $staticVersion = if ($literal.Success) { $literal.Groups[1].Value } elseif ($versionExpression -eq 'library_version' -and $podspec.Contains("pubspec['version'].gsub('+', '-')")) { $actualVersion.Replace('+','-') } else { $null }
  $lockedPodVersion = [regex]::Match($podLock,'(?m)^  - '+[regex]::Escape($name)+' \(([^)]+)\)').Groups[1].Value
  $checksumSection = ($podLock -split 'SPEC CHECKSUMS:')[1]
  $lockedChecksum = [regex]::Match($checksumSection,'(?m)^  '+[regex]::Escape($name)+': ([a-f0-9]{40})').Groups[1].Value
  Save-Evidence $pubspecPath "packages/$name/pubspec.yaml"
  Save-Evidence $podspecPath "packages/$name/$platformDirectory/$name.podspec"
  foreach ($f in (Get-ChildItem -LiteralPath $package -File | Where-Object Name -Match '^(LICENSE|LICENCE|NOTICE|COPYING)(\.|$)')) { Save-Evidence $f.FullName "packages/$name/$($f.Name)" }
  foreach ($rel in @('ios/firebase_sdk_version.rb','android/build.gradle','android/build.gradle.kts','android/gradle.properties')) {
    $p = Join-Path $package $rel
    if (Test-Path -LiteralPath $p) { Save-Evidence $p "packages/$name/$rel" }
  }
  $cacheHash = $null
  if ($sourceKind -eq 'hosted') {
    $hashPath = "$cache\hosted-hashes\pub.dev\$name-$version.sha256"
    if (Test-Path -LiteralPath $hashPath) { $cacheHash=(Get-Content -Raw -LiteralPath $hashPath).Trim(); Save-Evidence $hashPath "packages/$name/cache-archive.sha256" }
  }
  [ordered]@{
    package=$name; locked_pub_version=$version; source_kind=$sourceKind; locked_source_url=$downloadIdentity
    locked_archive_sha256=$archiveHash; cache_archive_hash_record=$cacheHash
    cache_hash_record_matches_lock=($sourceKind -eq 'hosted' -and $archiveHash -eq $cacheHash)
    archive_bytes_rehashed=$false; extracted_cache_authenticated_against_archive=$false
    locked_git_revision=$revision; cache_directory=$package
    observed_pubspec_name=$actualName; observed_pubspec_version=$actualVersion
    pubspec_identity_matches_lock=($actualName -eq $name -and $actualVersion -eq $version)
    pod_lock_external_path=$externalPath; locked_pod_version=$lockedPodVersion; locked_spec_checksum=$lockedChecksum
    observed_podspec_name_expression=$nameExpression; observed_podspec_version_expression=$versionExpression
    statically_derived_pod_version=$staticVersion; static_pod_version_matches_lock=($staticVersion -eq $lockedPodVersion)
    cocoapods_evaluated=$false; spec_checksum_verified=$false
    status='OBSERVED_LOCAL_CACHE_MAPPING_NOT_EXACT_NATIVE_VERIFICATION'
  }
}
[ordered]@{
  generated_utc=[DateTime]::UtcNow.ToString('o'); canonical_repository=$canonical
  purpose='New local-cache evidence inventory; not recovery of 48959137 or the missing historical checkpoint.'
  caveats=@('Hosted hash records are metadata, not rehashed archive bytes.', 'Copied cache files are hashed but cache extraction has not been authenticated against the published archive.', 'Podspecs are statically inspected only; no CocoaPods checksum replay has run.', 'Git cache revision must be independently checked with Git.', 'Wrapper licenses do not clear native SDK or transitive licensing obligations.')
  mappings=@($rows); files=@($files.ToArray())
} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$output\native-wrapper-cache-inventory.json" -Encoding utf8
$rows | ForEach-Object { "{0} pub={1}/{2} pod={3}/{4} hash-record={5}" -f $_.package,$_.locked_pub_version,$_.observed_pubspec_version,$_.locked_pod_version,$_.statically_derived_pod_version,$_.cache_hash_record_matches_lock }
"Mappings: $($rows.Count); preserved files: $($files.Count)"
