param(
  [Parameter(Mandatory=$true)][string]$DeviceId,
  [Parameter(Mandatory=$true)][string]$EvidenceDirectory
)
$ErrorActionPreference='Stop'
$client=Split-Path $PSScriptRoot -Parent
$apk=Join-Path $client 'build/app/outputs/flutter-apk/app-release.apk'
$package='dev.jjmusic.diagnostics.jj_music_mobile'
$logs=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Force $logs | Out-Null
if((& adb -s $DeviceId get-state) -ne 'device'){throw 'Selected device not online'}
$model=([string](& adb -s $DeviceId shell getprop ro.product.model)).Trim()
$token=[Guid]::NewGuid().ToString('N')
& adb -s $DeviceId install -r $apk *> (Join-Path $logs 'probe-install.log')
if($LASTEXITCODE -ne 0){throw 'Probe install failed'}
try {
  & adb -s $DeviceId shell am force-stop $package
  if($LASTEXITCODE -ne 0){throw 'Probe stop failed'}
  & adb -s $DeviceId shell am start -W -n "$package/.MainActivity" --es p1Token $token *> (Join-Path $logs 'probe-start.log')
  if($LASTEXITCODE -ne 0){throw 'Probe start failed'}
  $deadline=[DateTime]::UtcNow.AddSeconds(35)
  $proof=$null
  while([DateTime]::UtcNow -lt $deadline -and !$proof){
    $processId=([string](& adb -s $DeviceId shell pidof $package)).Trim()
    if($processId -match '^\d+$'){
      $lines=& adb -s $DeviceId logcat -d --pid=$processId -s 'JJOwnedProbe:I' '*:S'
      foreach($line in $lines){
        if($line -match 'JJOwnedProbe:\s*(\{.+\})'){
          $value=$Matches[1]|ConvertFrom-Json
          if($value.probeToken -eq $token -and [string]$value.pid -eq $processId){$proof=$value; break}
        }
      }
    }
    if(!$proof){Start-Sleep -Milliseconds 250}
  }
  if(!$proof){throw 'No fresh release focus proof; do not count as pass'}
  [ordered]@{device=$DeviceId;model=$model;entrypoint='lib/p1_focus_probe.dart';apkSha256=(Get-FileHash $apk -Algorithm SHA256).Hash.ToLower();proof=$proof} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $logs 'release-focus-proof.json') -Encoding utf8
  if($proof.stage -ne 'focus-passed' -or $proof.releaseMode -ne $true -or $proof.checks.Count -ne 5 -or $proof.consumers -ne 0 -or $proof.focusHeld -ne $false){throw 'Release focus checks failed; see proof JSON'}
  'Android release focus probe: 5 checks passed'
} finally {
  & adb -s $DeviceId shell am force-stop $package
}
