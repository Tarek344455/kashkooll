<#
.SYNOPSIS
    Opens the local Supabase cockpit (Studio) and keeps the backend scripts in view.

.DESCRIPTION
    Thin wrapper around scripts/start-dev-backend.ps1. The real stack is started
    by that script; this one only launches it and opens the local Studio UI.
#>
param(
    [switch]$Stop,
    [switch]$NoFunctions
)

$root = $PSScriptRoot
$script = Join-Path $root 'scripts\start-dev-backend.ps1'
$arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $script + '"'
if ($Stop) { $arguments += ' -Stop' }
if ($NoFunctions) { $arguments += ' -NoFunctions' }

if (-not $Stop) {
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WorkingDirectory $root -PassThru | Out-Null
    Write-Host '[cockpit] Supabase backend starting in a separate window...'
    Start-Sleep -Seconds 4
    Start-Process 'http://127.0.0.1:54323'
    Write-Host '[cockpit] Studio: http://127.0.0.1:54323'
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Stop
}
