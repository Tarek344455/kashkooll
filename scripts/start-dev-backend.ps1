<#
.SYNOPSIS
    Starts the local Supabase backend for Kashkool development.

.DESCRIPTION
    Boots the real Postgres/Auth/Realtime/Storage stack with the Supabase CLI,
    applies every migration in supabase/migrations plus supabase/seed.sql, and
    verifies the Auth and Data API health endpoints. No simulated backend, no mock
    service, no generated verification codes.

.PARAMETER Stop
    Stops the local stack instead of starting it.

.PARAMETER NoFunctions
    Do not serve the Deno Edge Functions (useful when only the DB is needed).

.PARAMETER ProjectDir
    Repository root. Defaults to the parent of this script's folder.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\start-dev-backend.ps1
    powershell -ExecutionPolicy Bypass -File scripts\start-dev-backend.ps1 -Stop
#>
param(
    [switch]$Stop,
    [switch]$NoFunctions,
    [string]$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$cli = Join-Path 'N:\spaceship-ai\tools\bin' 'supabase.cmd'
if (-not (Test-Path $cli)) {
    $found = Get-Command supabase -ErrorAction SilentlyContinue
    if ($found) { $cli = $found.Source }
    else { throw 'Supabase CLI is missing. Install it in N:\spaceship-ai\tools before starting the backend.' }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop is required by the Supabase local stack and is not on PATH.'
}
if (-not (docker info 2>$null)) {
    throw 'Docker is installed but its daemon is not running. Start Docker Desktop first.'
}

Push-Location $ProjectDir
try {
    if ($Stop) {
        & $cli stop
        Write-Host '[supabase] Local stack stopped.'
        return
    }

    Write-Host '[supabase] Starting local Postgres, Auth, Realtime and Studio...'
    & $cli start
    if ($LASTEXITCODE -ne 0) { throw 'supabase start failed.' }

    Write-Host '[supabase] Applying migrations and seed data...'
    & $cli db reset
    if ($LASTEXITCODE -ne 0) { throw 'supabase db reset failed — migrations did not apply cleanly.' }

    $endpoints = @(
        @{ Name = 'Auth'; Url = 'http://127.0.0.1:54321/auth/v1/health' },
        @{ Name = 'Data API'; Url = 'http://127.0.0.1:54321/rest/v1/' }
    )
    foreach ($endpoint in $endpoints) {
        $response = Invoke-WebRequest -Uri $endpoint.Url -TimeoutSec 15 -UseBasicParsing
        if ($response.StatusCode -ge 400) { throw "$($endpoint.Name) health check returned $($response.StatusCode)." }
        Write-Host "[ok] $($endpoint.Name) healthy: $($endpoint.Url)"
    }

    Write-Host '[ok] Studio:  http://127.0.0.1:54323'
    Write-Host '[ok] API:     http://127.0.0.1:54321'
    Write-Host '[i] Phone OTP requires a real SMS provider in supabase/config.toml. Without one the app shows an explicit not-configured error.'
    Write-Host '    Never paste a verification code into production code.'

    if (-not $NoFunctions) {
        $envFile = Join-Path $ProjectDir '.env.local'
        if (-not (Test-Path $envFile)) {
            throw "$envFile is missing. Copy .env.example to .env.local and fill in the real values before serving Edge Functions."
        }
        Write-Host '[supabase] Serving Edge Functions from supabase/functions...'
        & $cli functions serve --env-file $envFile
    }
}
finally {
    Pop-Location
}
