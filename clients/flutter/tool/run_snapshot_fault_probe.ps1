param(
  [Parameter(Mandatory=$true)][ValidateSet('Android','Windows')][string]$Platform,
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(Mandatory=$true)][string]$EvidenceDirectory,
  [string]$DeviceId
)
$ErrorActionPreference='Stop'
if($RunId -notmatch '^[A-Za-z0-9_-]{1,40}$'){throw 'Invalid run ID'}
if($Platform -eq 'Android' -and !$DeviceId){throw 'Explicit Android device required'}
$client=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $client '../..'))
$logs=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory $logs -Force | Out-Null
$proofPath=Join-Path $logs 'snapshot-faults-proof.json'
if(Test-Path $proofPath){throw 'Existing evidence; select a fresh directory'}
$adb='E:/Android/sdk/platform-tools/adb.exe'
$package='dev.jjmusic.diagnostics.jj_music_mobile'
$temporary=Join-Path $workspace "graphflow-out/snapshot-fault-$RunId"
$script:activeProbe=$null
$binary=if($Platform -eq 'Android'){
  Join-Path $client 'build/app/outputs/flutter-apk/app-release.apk'
}else{
  Join-Path $client 'build/windows/x64/runner/Release/jj_music_mobile.exe'
}
function Stop-Probe {
  if($Platform -eq 'Android'){
    & $adb -s $DeviceId shell am force-stop $package | Out-Null
    if($LASTEXITCODE -ne 0){throw 'Force-stop failed'}
    if((& $adb -s $DeviceId shell pidof $package)){throw 'Old process remains alive'}
  }elseif($script:activeProbe){
    if(!$script:activeProbe.HasExited){$script:activeProbe.Kill()}
    $script:activeProbe.WaitForExit()
    $script:activeProbe=$null
  }
}
function Start-Probe([string]$mode,[string]$scenario){
  $token=[Guid]::NewGuid().ToString('N')
  $launched=[DateTime]::UtcNow
  if($Platform -eq 'Android'){
    & $adb -s $DeviceId shell am start -W -n "$package/.MainActivity" --es p1Mode $mode --es p1Token $token *> (Join-Path $logs "$mode-start.log")
    if($LASTEXITCODE -ne 0){throw 'Android start failed'}
  }else{
    New-Item -ItemType Directory $temporary -Force | Out-Null
    $start=[Diagnostics.ProcessStartInfo]::new($binary,$mode)
    $start.WorkingDirectory=Split-Path $binary
    $start.UseShellExecute=$false
    $start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $start.EnvironmentVariables['TEMP']=$temporary
    $start.EnvironmentVariables['TMP']=$temporary
    $script:activeProbe=[Diagnostics.Process]::Start($start)
  }
  $deadline=[DateTime]::UtcNow.AddSeconds(20)
  while([DateTime]::UtcNow -lt $deadline){
    $value=$null
    if($Platform -eq 'Android'){
      $processId=([string](& $adb -s $DeviceId shell pidof $package)).Trim()
      if($processId -match '^\d+$'){
        $lines=& $adb -s $DeviceId logcat -d --pid=$processId -s 'JJOwnedProbe:I' '*:S'
        $lines | Set-Content (Join-Path $logs "$mode-native.log") -Encoding utf8
        foreach($line in $lines){
          if($line -match 'JJOwnedProbe:\s*(\{.+\})'){
            $candidate=$Matches[1] | ConvertFrom-Json
            if($candidate.probeToken -eq $token){$value=$candidate;break}
          }
        }
      }
    }else{
      if($script:activeProbe.HasExited){throw 'Probe exited before receipt'}
      $processId=[string]$script:activeProbe.Id
      $file=Join-Path $temporary "jj-owned-p1/proof-$processId.json"
      if((Test-Path $file) -and (Get-Item $file).LastWriteTimeUtc -ge $launched){
        $value=Get-Content $file -Raw | ConvertFrom-Json
      }
    }
    if($value){
      $value | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $logs "$mode-proof.json") -Encoding utf8
      if([string]$value.pid -ne $processId){throw 'PID mismatch'}
      if($value.stage -eq 'error'){throw "Probe failure: $($value.error)"}
      if($value.scenario -ne $scenario -or $value.runId -ne "$RunId-$scenario"){throw 'Run ID/scenario mismatch; rebuild the entrypoint'}
      return $value
    }
    Start-Sleep -Milliseconds 100
  }
  throw "Probe timed out: $mode"
}
$cases=@('missing','corrupt','unknown-version','unavailable-fixture','partial-temp','corrupt-newest')
$results=@()
try {
  if($Platform -eq 'Android'){
    & $adb -s $DeviceId install -r $binary *> (Join-Path $logs 'install.log')
    if($LASTEXITCODE -ne 0){throw 'Install failed'}
  }
  Stop-Probe
  foreach($scenario in $cases){
    $seed=Start-Probe "seed-$scenario" $scenario
    if($seed.stage -ne 'seeded' -or
        ($scenario -ne 'missing' -and (($seed.savedReceipts -join ',') -ne '1,2'))){throw 'Seed save receipts missing'}
    Stop-Probe # Real force kill, never graceful exit/save callbacks.
    $checked=Start-Probe "check-$scenario" $scenario
    $revision=switch($scenario){'partial-temp'{2};'corrupt-newest'{1};default{0}}
    $desired=if($revision -eq 0){'stopped'}else{'paused'}
    if($checked.stage -ne 'checked' -or $checked.pid -eq $seed.pid -or
       $checked.directory -ne $seed.directory -or $checked.revision -ne $revision -or
       $checked.desired -ne $desired -or $checked.consumers -ne 0 -or
       @($checked.nativeSamples).Count -ne 0 -or
       ($Platform -eq 'Android' -and ($checked.servicePresent -ne $false -or $checked.focusHeld -ne $false)) -or
       (ConvertTo-Json -Compress $checked.files) -ne (ConvertTo-Json -Compress $seed.files)){
      throw "Unsafe new-process fallback: $scenario"
    }
    $results+= [ordered]@{scenario=$scenario;forcedTermination=$true;seed=$seed;checked=$checked}
    Stop-Probe
    "$Platform $scenario passed"
  }
  [ordered]@{platform=$Platform;device=$DeviceId;entrypoint='lib/p1_snapshot_fault_probe.dart';binarySha256=(Get-FileHash $binary -Algorithm SHA256).Hash.ToLower();cases=$results} |
      ConvertTo-Json -Depth 15 | Set-Content $proofPath -Encoding utf8
} finally {
  Stop-Probe
}
# pidof deliberately returns 1 after a successful force-stop (no live process).
# Do not leak that expected native status as the completed controller result.
exit 0
