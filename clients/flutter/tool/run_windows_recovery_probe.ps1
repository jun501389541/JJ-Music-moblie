$ErrorActionPreference='Stop'
$client=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $client '../..'))
$temporary=Join-Path $workspace 'graphflow-out/p1-process-temp'
if(!$temporary.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar)){throw 'Invalid isolated root'}
New-Item -ItemType Directory $temporary -Force | Out-Null
$exe=Join-Path $client 'build/windows/x64/runner/Release/jj_music_mobile.exe'
function Start-Probe([string]$mode) {
  $start=[Diagnostics.ProcessStartInfo]::new($exe,$mode)
  $start.WorkingDirectory=Split-Path $exe
  $start.UseShellExecute=$false
  $start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
  $start.EnvironmentVariables['TEMP']=$temporary
  $start.EnvironmentVariables['TMP']=$temporary
  $launched=[DateTime]::UtcNow
  $process=[Diagnostics.Process]::Start($start)
  $file=Join-Path $temporary "jj-owned-p1/proof-$($process.Id).json"
  $deadline=[DateTime]::UtcNow.AddSeconds(25)
  while([DateTime]::UtcNow -lt $deadline -and !$process.HasExited){
    if((Test-Path $file) -and (Get-Item $file).LastWriteTimeUtc -ge $launched){
      $value=Get-Content $file -Raw | ConvertFrom-Json
      if($value.pid -ne $process.Id){throw 'Probe PID mismatch'}
      if($value.stage -eq 'error'){ $process.Kill();throw "Probe failure: $($value.error)" }
      return @{process=$process;proof=$value}
    }
    Start-Sleep -Milliseconds 100
  }
  if(!$process.HasExited){$process.Kill()}
  throw 'Probe receipt timed out'
}
$saved=Start-Probe 'save'
if($saved.proof.stage -ne 'saved' -or $saved.proof.revision -lt 1){throw 'No saved receipt'}
# Kill only the exact Process instance started above. Never rely on graceful exit.
$saved.process.Kill(); $saved.process.WaitForExit()
$loaded=Start-Probe 'restore'
try {
  if($loaded.proof.stage -ne 'loaded' -or $loaded.proof.pid -eq $saved.proof.pid -or
    $loaded.proof.coordinatorEpoch -eq $saved.proof.coordinatorEpoch -or
    $loaded.proof.revision -ne $saved.proof.revision -or
    $loaded.proof.session -ne $saved.proof.session -or
    $loaded.proof.position -ne $saved.proof.position -or
    $loaded.proof.desired -ne 'paused' -or $loaded.proof.consumers -ne 0 -or
    (ConvertTo-Json -Compress $loaded.proof.confirmations) -ne (ConvertTo-Json -Compress $saved.proof.confirmations)) {throw 'Cross-process recovery mismatch'}
  $output=[ordered]@{platform='windows';sameBinarySha256=(Get-FileHash $exe -Algorithm SHA256).Hash.ToLower();dartAssetSha256=(Get-FileHash (Join-Path (Split-Path $exe) 'data/app.so') -Algorithm SHA256).Hash.ToLower();forcedTermination=$true;saved=$saved.proof;loaded=$loaded.proof}
  $output | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $workspace 'docs/flutter-migration/evidence/p1-a/20261031/windows-process-proof.json') -Encoding utf8
  'Windows two-process forced-termination recovery passed'
} finally {
  if(!$loaded.process.HasExited){$loaded.process.Kill();$loaded.process.WaitForExit()}
}
