# Sync script for Kashkool monorepo
$root = "N:\opencode\projects\kashkool"
if (!(Test-Path "$root\CLAUDE.md")) {
    Copy-Item "$root\AGENTS.md" "$root\CLAUDE.md"
}
Write-Host "Sync Complete: AGENTS.md <-> CLAUDE.md"
