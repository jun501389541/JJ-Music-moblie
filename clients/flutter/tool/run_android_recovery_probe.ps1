param(
  [Parameter(Mandatory=$true)][string]$DeviceId,
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(Mandatory=$true)][string]$EvidenceDirectory
)
$ErrorActionPreference='Stop'
$client=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $client '../..'))
$logs=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory $logs -Force | Out-Null
$proofPath=Join-Path $logs 'android-process-proof.json'
if(Test-Path $proofPath){throw 'Evidence already exists; choose a fresh directory'}
$adb='E:/Android/sdk/platform-tools/adb.exe'
$package='dev.jjmusic.diagnostics.jj_music_mobile'
$apk=Join-Path $client 'build/app/outputs/flutter-apk/app-release.apk'
& $adb -s $DeviceId install -r $apk
if($LASTEXITCODE -ne 0){throw 'Installation failed'}
function Start-Probe([string]$mode){
  $token=[Guid]::NewGuid().ToString('N')
  & $adb -s $DeviceId shell am start -n "$package/.MainActivity" --es p1Mode $mode --es p1Token $token | Out-Null
  if($LASTEXITCODE -ne 0){throw 'Start failed'}
  $deadline=[DateTime]::UtcNow.AddSeconds(25)
  while([DateTime]::UtcNow -lt $deadline){
    $processId=([string](& $adb -s $DeviceId shell pidof $package)).Trim()
    if($processId -match '^\d+$'){
      $log=& $adb -s $DeviceId logcat -d --pid=$processId -s 'JJOwnedProbe:I' '*:S'
      $log | Set-Content (Join-Path $logs "stage-$mode.log") -Encoding utf8
      foreach($line in $log){
        if($line -match 'JJOwnedProbe:\s*(\{.+\})'){
          $value=$Matches[1]|ConvertFrom-Json
          if($value.probeToken -ne $token){continue}
          if([string]$value.pid -ne $processId){throw 'Probe PID mismatch'}
          if($value.stage -eq 'error'){throw "Probe failure: $($value.error)"}
          if($value.runId -ne $RunId){throw 'Probe run ID mismatch; rebuild with P1_RUN_ID'}
          return $value
        }
      }
    }
    Start-Sleep -Milliseconds 250
  }
  throw 'Android proof timed out'
}
& $adb -s $DeviceId shell am force-stop $package
try {
$saved=Start-Probe 'save'
if($saved.stage -ne 'saved' -or $saved.revision -lt 1){throw 'No saved receipt'}
& $adb -s $DeviceId shell am force-stop $package
if((& $adb -s $DeviceId shell pidof $package)){throw 'Old process still alive'}
$loaded=Start-Probe 'restore'
  if($loaded.stage -ne 'loaded' -or $loaded.pid -eq $saved.pid -or
     $loaded.coordinatorEpoch -eq $saved.coordinatorEpoch -or
     $loaded.session -ne $saved.session -or $loaded.revision -ne $saved.revision -or
     $loaded.position -ne $saved.position -or $loaded.desired -ne 'paused' -or $loaded.consumers -ne 0 -or
     $loaded.fixture -ne $saved.fixture -or $loaded.directory -ne $saved.directory -or
     $loaded.staleClaimRejected -ne 'stale-controller' -or $loaded.stoppedConsumers -ne 0 -or
     $loaded.resumedPosition -le ($saved.position+300) -or
     $loaded.repeatResumeDeduplicated -ne $true -or
     (ConvertTo-Json -Depth 8 -Compress $loaded.diskSnapshot) -ne (ConvertTo-Json -Depth 8 -Compress $saved.diskSnapshot) -or
     (ConvertTo-Json -Compress $loaded.confirmations) -ne (ConvertTo-Json -Compress $saved.confirmations)) {throw 'Android cross-process mismatch'}
  [ordered]@{platform='android';device=$DeviceId;apkSha256=(Get-FileHash $apk -Algorithm SHA256).Hash.ToLower();forcedTermination=$true;saved=$saved;loaded=$loaded} | ConvertTo-Json -Depth 12 | Set-Content $proofPath -Encoding utf8
  'Android two-process force-stop recovery passed'
}finally{& $adb -s $DeviceId shell am force-stop $package}
