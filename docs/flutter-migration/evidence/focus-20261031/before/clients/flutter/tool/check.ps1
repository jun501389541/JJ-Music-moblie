param(
  [ValidateSet('Quality','AndroidRelease','WindowsRelease','All')]
  [string]$Mode='Quality',
  [string]$EvidenceDirectory
)
$ErrorActionPreference='Stop'
$client=Split-Path $PSScriptRoot -Parent
if(!$EvidenceDirectory){
  $EvidenceDirectory=Join-Path $client '../../graphflow-out/checks'
}
$logs=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory $logs -Force | Out-Null
function Assert-Result([string]$name){
  $result=$LASTEXITCODE
  if($result -ne 0){
    Get-Content (Join-Path $logs "$name.log") -Tail 20
    throw "$name failed (exit $result); see $logs"
  }
  Write-Output "$name passed"
}
Push-Location $client
try {
  if($Mode -in @('Quality','All')){
    & flutter pub get --enforce-lockfile *> (Join-Path $logs 'pub-get.log')
    Assert-Result 'pub-get'
    $freeze=Get-Content (Join-Path $client '../../docs/flutter-migration/evidence/A02/20261031-bootstrap-freeze.json') -Raw | ConvertFrom-Json
    $workspace=[IO.Path]::GetFullPath((Join-Path $client '../..'))
    foreach($entry in $freeze.files){
      if((Get-FileHash (Join-Path $workspace $entry.path) -Algorithm SHA256).Hash.ToLower() -ne $entry.sha256){
        throw "Frozen contract drift: $($entry.path)"
      }
    }
    $authority=Join-Path $workspace 'docs/flutter-migration/05-architecture-contracts.md'
    if((Get-FileHash $authority -Algorithm SHA256).Hash.ToLower() -ne $freeze.authorityContractSha256){throw 'Authority contract drift'}
    Write-Output 'contract hashes passed'
    & dart format --output=none --set-exit-if-changed lib test integration_test tool *> (Join-Path $logs 'format.log')
    Assert-Result 'format'
    & flutter analyze --no-pub *> (Join-Path $logs 'analyze.log')
    Assert-Result 'analyze'
    & flutter test --no-pub --reporter expanded *> (Join-Path $logs 'tests.log')
    Assert-Result 'tests'
  }
  if($Mode -in @('AndroidRelease','All')){
    # Flutter must refresh generated dev-plugin registrants after integration tests.
    $lockHash=(Get-FileHash pubspec.lock -Algorithm SHA256).Hash
    & (Join-Path $PSScriptRoot 'flutter_with_proxy.ps1') -FlutterArgs @('build','apk','--release','--target','lib/main.dart') *> (Join-Path $logs 'android-build.log')
    Assert-Result 'android-build'
    if((Get-FileHash pubspec.lock -Algorithm SHA256).Hash -ne $lockHash){throw 'Build changed dependency lockfile'}
  }
  if($Mode -in @('WindowsRelease','All')){
    $lockHash=(Get-FileHash pubspec.lock -Algorithm SHA256).Hash
    & flutter build windows --release --target lib/main.dart *> (Join-Path $logs 'windows-build.log')
    Assert-Result 'windows-build'
    if((Get-FileHash pubspec.lock -Algorithm SHA256).Hash -ne $lockHash){throw 'Build changed dependency lockfile'}
  }
} catch {
  Write-Error -Message $_ -ErrorAction Continue
  exit 1
} finally { Pop-Location }
exit 0
