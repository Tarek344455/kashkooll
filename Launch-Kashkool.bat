@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Launch-Kashkool Dev Cockpit

echo ========================================================
echo   KASHKOOL ECOSYSTEM - ONE-CLICK DEV COCKPIT LAUNCHER
echo ========================================================

:: 1. Ensure N: drive subst
if not exist "N:\" (
  echo [cockpit] Mapping N: to E:\ ...
  subst N: E:\ >nul 2>&1
)

set "ROUTEDIR=N:\opencode\projects\claude-omni-plugin"
set "PROJECTDIR=N:\opencode\projects\kashkool"

:: 2. Configure Router PORT=4000 in .env if needed
cd /d "%ROUTEDIR%
if exist ".env" (
  powershell -Command "(Get-Content '.env') -replace '^OMNI_PORT=.*', 'OMNI_PORT=4000' | Set-Content '.env'"
) else (
  copy /y ".env.example" ".env" >nul
  powershell -Command "(Get-Content '.env') -replace '^OMNI_PORT=.*', 'OMNI_PORT=4000' | Set-Content '.env'"
)

echo [cockpit] Starting Omni-Router on port 4000 in background...
call start-omni.bat serve

echo [cockpit] Verifying Omni-Router health...
powershell -Command "$r = Invoke-RestMethod 'http://127.0.0.1:4000/health' -TimeoutSec 5; Write-Host ('[OK] Router healthy. Providers: ' + ($r.providers -join ', '))"

echo [cockpit] Launching local Supabase stack (Postgres, Auth, Realtime, Edge Functions)...
start "Supabase Backend" powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECTDIR%\scripts\start-dev-backend.ps1"

echo [cockpit] Opening OpenCode in %PROJECTDIR% ...
cd /d "%PROJECTDIR%
if exist "%LOCALAPPDATA%\Programs\opencode\opencode.exe" (
  start "" "%LOCALAPPDATA%\Programs\opencode\opencode.exe" "%PROJECTDIR%"
) else (
  echo [cockpit] OpenCode executable not found in default path, please open manually in %PROJECTDIR%
)

echo ========================================================
echo   DEV COCKPIT READY! Mini-Step 1 awaits your execution.
echo ========================================================
pause
endlocal
