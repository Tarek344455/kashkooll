<#
.SYNOPSIS
    Builds release APKs for the Kashkool apps (customer + admin).

.DESCRIPTION
    Wraps the Flutter/Gradle toolchain with the machine-specific paths that the
    Android build needs on this workstation (Flutter SDK, JDK 17, Android SDK).

    Output:
        apps/kashkool_app/build/app/outputs/flutter-apk/app-release.apk
        apps/kashkool_admin/build/app/outputs/flutter-apk/app-release.apk

.EXAMPLE
    .\build-apk.ps1
    .\build-apk.ps1 -App admin
#>
[CmdletBinding()]
param(
    [ValidateSet('app', 'admin', 'all')]
    [string] $App = 'all',

    [switch] $SplitPerAbi
)

$ErrorActionPreference = 'Stop'

$repoRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterSdk  = 'C:\src\flutter'
$javaHome    = 'C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot'
$androidSdk  = 'C:\Android\Sdk'

foreach ($path in @($flutterSdk, $javaHome, $androidSdk)) {
    if (-not (Test-Path $path)) {
        throw "Required toolchain path missing: $path"
    }
}

$env:JAVA_HOME     = $javaHome
$env:ANDROID_HOME  = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:PATH          = "C:\Program Files\Git\cmd;$javaHome\bin;$flutterSdk\bin;$env:PATH"

$flutter = Join-Path $flutterSdk 'bin\flutter.bat'

function Build-KashkoolApp {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Directory
    )

    if (-not (Test-Path $Directory)) {
        throw "App directory not found: $Directory"
    }

    Write-Host "==> Building $Name" -ForegroundColor Cyan
    Push-Location $Directory
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "pub get failed for $Name" }

        $buildArgs = @('build', 'apk', '--release')
        if ($SplitPerAbi) { $buildArgs += '--split-per-abi' }

        & $flutter @buildArgs
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed for $Name" }
    }
    finally {
        Pop-Location
    }

    $apkDir = Join-Path $Directory 'build\app\outputs\flutter-apk'
    Get-ChildItem $apkDir -Filter '*.apk' |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object {
            Write-Host ("    {0}  ({1:N1} MB)" -f $_.FullName, ($_.Length / 1MB)) -ForegroundColor Green
        }
}

$targets = @()
if ($App -in @('app', 'all'))   { $targets += @{ Name = 'kashkool_app';   Directory = (Join-Path $repoRoot 'apps\kashkool_app') } }
if ($App -in @('admin', 'all')) { $targets += @{ Name = 'kashkool_admin'; Directory = (Join-Path $repoRoot 'apps\kashkool_admin') } }

foreach ($target in $targets) {
    Build-KashkoolApp -Name $target.Name -Directory $target.Directory
}

Write-Host 'All requested APKs built.' -ForegroundColor Green
