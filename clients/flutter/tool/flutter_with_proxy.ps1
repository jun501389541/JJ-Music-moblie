# Map the existing proxy to Java only for this child build process. No global writes.
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FlutterArgs)
$oldOptions=$env:JAVA_TOOL_OPTIONS
$oldGradleHome=$env:GRADLE_USER_HOME
$oldReadOnlyCache=$env:GRADLE_RO_DEP_CACHE
try {
  # Isolate this prototype from pre-existing user init scripts used by other apps.
  $projectRoot=Split-Path $PSScriptRoot -Parent
  $env:GRADLE_USER_HOME=Join-Path $projectRoot '.gradle-user-home'
    $initDirectory=Join-Path $env:GRADLE_USER_HOME 'init.d'
  New-Item -ItemType Directory $initDirectory -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'gradle_repositories.init.gradle') -Destination (Join-Path $initDirectory 'project-repositories.gradle') -Force
  if($oldGradleHome -and (Test-Path (Join-Path $oldGradleHome 'caches/modules-2'))){$env:GRADLE_RO_DEP_CACHE=Join-Path $oldGradleHome 'caches'}
  $cache=Join-Path $env:GRADLE_USER_HOME 'wrapper/dists/gradle-9.3.1-bin/30eg2jcb8eqk5ro0gq9h8x6ef'
  $download=Join-Path $projectRoot '.dart_tool/gradle-download/gradle-9.3.1-bin.zip'
  if(!(Test-Path (Join-Path $cache 'gradle-9.3.1/bin/gradle.bat')) -and (Test-Path $download)){
    if((Get-FileHash $download -Algorithm SHA256).Hash.ToLower() -ne 'b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06'){throw 'Gradle checksum mismatch'}
    New-Item -ItemType Directory $cache -Force | Out-Null
    Copy-Item -LiteralPath $download -Destination (Join-Path $cache 'gradle-9.3.1-bin.zip')
  }
  if($env:HTTPS_PROXY -or $env:HTTP_PROXY) {
    $proxyText=if($env:HTTPS_PROXY){$env:HTTPS_PROXY}else{$env:HTTP_PROXY}
    $proxyUri=[Uri]$proxyText
    if($proxyUri.UserInfo){throw 'Authenticated proxy needs a separate credential-safe setup'}
    $env:JAVA_TOOL_OPTIONS=($oldOptions+' -Dhttps.proxyHost='+$proxyUri.Host+' -Dhttps.proxyPort='+$proxyUri.Port+' -Dhttp.proxyHost='+$proxyUri.Host+' -Dhttp.proxyPort='+$proxyUri.Port+' -Dhttp.nonProxyHosts=localhost|127.*|[::1]').Trim()
  }
  & flutter @FlutterArgs
  $result=$LASTEXITCODE
} finally { $env:JAVA_TOOL_OPTIONS=$oldOptions; $env:GRADLE_USER_HOME=$oldGradleHome; $env:GRADLE_RO_DEP_CACHE=$oldReadOnlyCache }
exit $result


