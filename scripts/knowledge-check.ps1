<# 
.SYNOPSIS
Run Savior Knowledge Base checks on the Kashkool monorepo
.DESCRIPTION
Executes architecture, financial, and security guard rules against the codebase.
.PARAMETER ChangedFiles
Optional list of changed files to check (for pre-commit hooks)
.PARAMETER KnowledgeRoot
Path to Savior Engine knowledge base (default: ~/.config/opencode/kashkool-savior/knowledge)
.EXAMPLE
.\scripts\knowledge-check.ps1
.EXAMPLE
.\scripts\knowledge-check.ps1 -ChangedFiles "apps/kashkool_app/lib/main.dart", "packages/kashkool_core/lib/models/payment.dart"
#>

param(
    [string[]]$ChangedFiles = @(),
    [string]$KnowledgeRoot = "$env:USERPROFILE\.config\opencode\kashkool-savior\knowledge"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Kashkool Savior Knowledge Gate ===" -ForegroundColor Cyan
Write-Host "Knowledge Root: $KnowledgeRoot" -ForegroundColor Gray

# Verify Savior Engine exists
$saviorCli = "$env:USERPROFILE\.config\opencode\kashkool-savior\cli\knowledge.mjs"
if (-not (Test-Path $saviorCli)) {
    Write-Error "Savior Engine CLI not found at $saviorCli"
    Write-Host "Run: git clone https://github.com/kashkool/savior-engine.git $env:USERPROFILE\.config\opencode\kashkool-savior" -ForegroundColor Yellow
    exit 1
}

# Build args
$args = @("check:project")
if ($ChangedFiles.Count -gt 0) {
    $args += "--changed"
    $args += $ChangedFiles
}

Write-Host "Running: node $saviorCli $($args -join ' ')" -ForegroundColor Gray
Write-Host ""

# Execute
$exitCode = 0
try {
    & node $saviorCli @args
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error "Failed to execute knowledge check: $_"
    $exitCode = 1
}

if ($exitCode -eq 0) {
    Write-Host "`n✅ Knowledge Gate: PASSED" -ForegroundColor Green
} elseif ($exitCode -eq 1) {
    Write-Host "`n⚠️  Knowledge Gate: REQUIRES HUMAN REVIEW (high severity)" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Knowledge Gate: BLOCKED (critical severity)" -ForegroundColor Red
}

exit $exitCode