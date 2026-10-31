# Fixed official Gradle 9.3.1 binary distribution. No global configuration writes.
$ErrorActionPreference='Stop'
$root=Join-Path $PSScriptRoot '../.dart_tool/gradle-download'
$total=137037885L
$size=[long][Math]::Ceiling($total/24)
0..23 | ForEach-Object -Parallel {
  $p=Join-Path $using:root ('part-{0:D2}.bin' -f $_)
  $start=[long]$_*$using:size
  $end=[Math]::Min($start+$using:size-1,$using:total-1)
  for($try=0;$try -lt 20;$try++){
    $have=if(Test-Path $p){(Get-Item $p).Length}else{0L}
    if($have -eq ($end-$start+1)){break}
    if($have -gt ($end-$start+1)){throw 'Oversize chunk'}
    $from=$start+$have
    curl.exe -fsSL --connect-timeout 12 --max-time 30 --range "$from-$end" --dump-header "$p.headers" --output "$p.tail" https://downloads.gradle.org/distributions/gradle-9.3.1-bin.zip 2>$null
    if((Test-Path "$p.tail") -and ((Get-Content "$p.headers" -Raw) -match "(?im)^content-range: bytes $from-$end/137037885")){
      $length=(Get-Item "$p.tail").Length
      if($length -gt 0 -and $length -le ($end-$from+1)){
        $a=[IO.File]::Open($p,[IO.FileMode]::Append);$b=[IO.File]::OpenRead("$p.tail")
        try{$b.CopyTo($a)}finally{$b.Dispose();$a.Dispose()}
      }
    }
  }
  if(!(Test-Path $p) -or (Get-Item $p).Length -ne ($end-$start+1)){throw "Incomplete chunk $_"}
  "Gradle chunk $_ complete"
} -ThrottleLimit 24
$parts=Get-ChildItem $root -Filter 'part-*.bin' | Sort-Object Name
if($parts.Count -ne 24 -or ($parts|Measure-Object Length -Sum).Sum -ne $total){throw 'Incomplete Gradle download'}
$zip=Join-Path $root 'gradle-9.3.1-bin.zip'
$out=[IO.File]::Create($zip)
try{foreach($part in $parts){$inputFile=[IO.File]::OpenRead($part.FullName);try{$inputFile.CopyTo($out)}finally{$inputFile.Dispose()}}}finally{$out.Dispose()}
$hash=(Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if($hash -ne 'b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06'){throw 'Gradle official SHA256 mismatch'}
$cache=Join-Path (Split-Path $PSScriptRoot -Parent) '.gradle-user-home/wrapper/dists/gradle-9.3.1-bin/30eg2jcb8eqk5ro0gq9h8x6ef'
New-Item -ItemType Directory $cache -Force | Out-Null
Copy-Item -LiteralPath $zip -Destination (Join-Path $cache 'gradle-9.3.1-bin.zip')
"Verified Gradle SHA256=$hash and seeded project wrapper cache"
