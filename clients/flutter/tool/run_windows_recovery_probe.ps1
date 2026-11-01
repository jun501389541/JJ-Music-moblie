param(
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(Mandatory=$true)][string]$EvidenceDirectory
)
$ErrorActionPreference='Stop'
$client=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $client '../..'))
if($RunId -notmatch '^[A-Za-z0-9_-]{1,80}$'){throw 'Invalid run ID'}
$temporary=Join-Path $workspace "graphflow-out/p1-process-$RunId"
if(!$temporary.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar)){throw 'Invalid isolated root'}
New-Item -ItemType Directory $temporary -Force | Out-Null
$logs=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory $logs -Force | Out-Null
$proofPath=Join-Path $logs 'windows-process-proof.json'
if(Test-Path $proofPath){throw 'Evidence already exists; choose a fresh directory'}
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
  try {
  $file=Join-Path $temporary "jj-owned-p1/proof-$($process.Id).json"
  $deadline=[DateTime]::UtcNow.AddSeconds(25)
  while([DateTime]::UtcNow -lt $deadline -and !$process.HasExited){
    if((Test-Path $file) -and (Get-Item $file).LastWriteTimeUtc -ge $launched){
      # The producer flushes a small JSON file; existence alone is not a full
      # receipt. A partial read is retried within the same bounded deadline.
      try {$value=Get-Content $file -Raw | ConvertFrom-Json -ErrorAction Stop}
      catch {Start-Sleep -Milliseconds 100; continue}
      if(!$value){Start-Sleep -Milliseconds 100; continue}
      if($value.pid -ne $process.Id){throw 'Probe PID mismatch'}
      if($value.stage -eq 'error'){ $process.Kill();throw "Probe failure: $($value.error)" }
      if($value.runId -ne $RunId){throw 'Probe run ID mismatch; rebuild with P1_RUN_ID'}
      return @{process=$process;proof=$value}
    }
    Start-Sleep -Milliseconds 100
  }
  if(!$process.HasExited){$process.Kill()}
  throw 'Probe receipt timed out'
  } catch {
    if(!$process.HasExited){$process.Kill();$process.WaitForExit()}
    throw
  }
}
$saved=$null
$loaded=$null
try {
$saved=Start-Probe 'save'
if($saved.proof.stage -ne 'saved' -or $saved.proof.revision -lt 1){throw 'No saved receipt'}
# Kill only the exact Process instance started above. Never rely on graceful exit.
$saved.process.Kill(); $saved.process.WaitForExit()
$loaded=Start-Probe 'restore'
  if($loaded.proof.stage -ne 'loaded' -or $loaded.proof.pid -eq $saved.proof.pid -or
    $loaded.proof.coordinatorEpoch -eq $saved.proof.coordinatorEpoch -or
    $loaded.proof.revision -ne $saved.proof.revision -or
    $loaded.proof.session -ne $saved.proof.session -or
    $loaded.proof.position -ne $saved.proof.position -or
    $loaded.proof.desired -ne 'paused' -or $loaded.proof.consumers -ne 0 -or
    $loaded.proof.fixture -ne $saved.proof.fixture -or $loaded.proof.directory -ne $saved.proof.directory -or
    $loaded.proof.staleClaimRejected -ne 'stale-controller' -or $loaded.proof.stoppedConsumers -ne 0 -or
    $loaded.proof.resumedPosition -le ($saved.proof.position+300) -or
    $loaded.proof.repeatResumeDeduplicated -ne $true -or
    (ConvertTo-Json -Depth 8 -Compress $loaded.proof.diskSnapshot) -ne (ConvertTo-Json -Depth 8 -Compress $saved.proof.diskSnapshot) -or
    (ConvertTo-Json -Compress $loaded.proof.confirmations) -ne (ConvertTo-Json -Compress $saved.proof.confirmations)) {throw 'Cross-process recovery mismatch'}
  $output=[ordered]@{platform='windows';sameBinarySha256=(Get-FileHash $exe -Algorithm SHA256).Hash.ToLower();dartAssetSha256=(Get-FileHash (Join-Path (Split-Path $exe) 'data/app.so') -Algorithm SHA256).Hash.ToLower();forcedTermination=$true;saved=$saved.proof;loaded=$loaded.proof}
  $output | ConvertTo-Json -Depth 12 | Set-Content $proofPath -Encoding utf8
  'Windows two-process forced-termination recovery passed'
} finally {
  foreach($instance in @($saved,$loaded)){
    if($instance -and !$instance.process.HasExited){$instance.process.Kill();$instance.process.WaitForExit()}
  }
}
