<#
.SYNOPSIS
    Installs the freshly built Kashkool APKs onto the connected Android phone.
#>
[CmdletBinding()]
param(
    [string] $Device = 'XMJ4C19C13000781'
)

$ErrorActionPreference = 'Stop'
$adb = 'C:\Android\Sdk\platform-tools\adb.exe'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$apks = @(
    @{ Name = 'kashkool_app';   Path = Join-Path $root 'apps\kashkool_app\build\app\outputs\flutter-apk\app-release.apk' },
    @{ Name = 'kashkool_admin'; Path = Join-Path $root 'apps\kashkool_admin\build\app\outputs\flutter-apk\app-release.apk' }
)

Write-Host "Connected devices:" -ForegroundColor Cyan
& $adb devices

foreach ($apk in $apks) {
    if (-not (Test-Path $apk.Path)) {
        Write-Host "MISSING: $($apk.Path)" -ForegroundColor Red
        continue
    }
    $size = [math]::Round((Get-Item $apk.Path).Length / 1MB, 1)
    Write-Host "Installing $($apk.Name) ($size MB) ..." -ForegroundColor Cyan
    & $adb -s $Device install -r $apk.Path
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK: $($apk.Name)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: $($apk.Name) (exit $LASTEXITCODE)" -ForegroundColor Red
    }
}

Write-Host "Installed Kashkool packages:" -ForegroundColor Cyan
& $adb -s $Device shell pm list packages | Select-String 'kashkool'
