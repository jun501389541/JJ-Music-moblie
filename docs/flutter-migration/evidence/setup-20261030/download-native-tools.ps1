# Environment preparation only. Fixed Google package metadata from repository2-3.xml.
$ErrorActionPreference = 'Stop'
$packages = @(
    @{ Name='android-ndk-r28c-windows.zip'; Size=748118221L; Sha1='086bba43ff2f5eb0e387b15c8278bb4e0d89ba1d'; Segments=64 },
    @{ Name='cmake-3.22.1-windows.zip'; Size=16116742L; Sha1='292778f32a7d5183e1c49c7897b870653f2d2c1b'; Segments=8 }
)
$segments = foreach ($package in $packages) {
    $directory = Join-Path 'E:\SDKs\downloads' ($package.Name + '.parts')
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $chunk = [long][Math]::Ceiling($package.Size / $package.Segments)
    for ($index=0; $index -lt $package.Segments; $index++) {
        $start = [long]$index * $chunk
        @{ Name=$package.Name; Total=$package.Size; Start=$start;
           End=[Math]::Min($start+$chunk-1,$package.Size-1);
           Path=(Join-Path $directory ('part-{0:D2}.bin' -f $index)) }
    }
}
$segments | ForEach-Object -Parallel {
    $segment = $_
    $expected = $segment.End - $segment.Start + 1
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        $have = if (Test-Path -LiteralPath $segment.Path) { (Get-Item -LiteralPath $segment.Path).Length } else { 0L }
        if ($have -eq $expected) { break }
        if ($have -gt $expected) { throw 'Oversized segment; refusing to append' }
        $from = $segment.Start + $have
        $tail = $segment.Path + '.tail'
        $headers = $segment.Path + '.headers'
        $url = 'https://dl.google.com/android/repository/' + $segment.Name
        curl.exe -sSL --fail --connect-timeout 12 --max-time 45 --range "$from-$($segment.End)" --dump-header $headers --output $tail $url 2>$null
        if ((Test-Path -LiteralPath $tail) -and (Test-Path -LiteralPath $headers)) {
            $pattern = '(?im)^content-range: bytes ' + $from + '-' + $segment.End + '/' + $segment.Total
            $length = (Get-Item -LiteralPath $tail).Length
            if ((Get-Content -LiteralPath $headers -Raw) -match $pattern -and $length -gt 0 -and $length -le ($expected-$have)) {
                $output = [IO.File]::Open($segment.Path,[IO.FileMode]::Append)
                $inputFile = [IO.File]::OpenRead($tail)
                try { $inputFile.CopyTo($output) } finally { $inputFile.Dispose(); $output.Dispose() }
            }
        }
    }
    $length = if (Test-Path -LiteralPath $segment.Path) { (Get-Item -LiteralPath $segment.Path).Length } else { 0L }
    if ($length -ne $expected) { throw "Incomplete segment $($segment.Name) $($segment.Start)" }
    "$($segment.Name) segment $($segment.Start) complete"
} -ThrottleLimit 64
foreach ($package in $packages) {
    $directory = Join-Path 'E:\SDKs\downloads' ($package.Name + '.parts')
    $parts = Get-ChildItem -LiteralPath $directory -Filter 'part-*.bin' | Sort-Object Name
    if ($parts.Count -ne $package.Segments -or ($parts | Measure-Object Length -Sum).Sum -ne $package.Size) {
        throw "Incomplete download: $($package.Name)"
    }
    $target = Join-Path 'E:\SDKs\downloads' $package.Name
    $output = [IO.File]::Create($target)
    try {
        foreach ($part in $parts) {
            $inputFile = [IO.File]::OpenRead($part.FullName)
            try { $inputFile.CopyTo($output) } finally { $inputFile.Dispose() }
        }
    } finally { $output.Dispose() }
    $hash = (Get-FileHash -LiteralPath $target -Algorithm SHA1).Hash.ToLower()
    if ($hash -ne $package.Sha1) { throw "Google package checksum mismatch: $($package.Name)" }
    "Verified $($package.Name) SHA1=$hash"
    # Seed only this package's SDK archive cache immediately before installing it.
    # The official installer purges other unused archives after each installation.
}
