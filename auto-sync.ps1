<#
.SYNOPSIS
    Kashkool auto-sync daemon: commit + push automatically after every burst of work.

.DESCRIPTION
    Watches the working tree. Once edits have been quiet for -QuietSeconds it stages
    everything, commits a snapshot and pushes it to the remote. If the network is down
    the commit stays local and the push is retried every -PushRetrySeconds, so no work
    is ever lost. If the remote moved ahead, it rebases and retries once.

.EXAMPLE
    .\auto-sync.ps1
    Run continuously (default): snapshots every ~1 minute of activity.

.EXAMPLE
    .\auto-sync.ps1 -Once
    One snapshot + push, then exit. Good for a hotkey or Task Scheduler.

.EXAMPLE
    .\auto-sync.ps1 -QuietSeconds 20 -Branch main
    Snappier cadence on a different branch.

.EXAMPLE
    .\auto-sync.ps1 -Stop
    Stop a daemon started earlier.
#>
[CmdletBinding()]
param(
    [string] $Repo             = '',
    [string] $Branch           = 'develop',
    [string] $Remote           = 'origin',
    [int]    $QuietSeconds     = 60,
    [int]    $PollSeconds      = 5,
    [int]    $PushRetrySeconds = 90,
    [switch] $Once,
    [switch] $Stop
)

$ErrorActionPreference = 'Continue'

# $PSScriptRoot is not always populated during parameter binding (notably with -File),
# so resolve the repo root here instead of as a param default.
if (-not $Repo) {
    if ($PSScriptRoot) { $Repo = $PSScriptRoot }
    else { $Repo = (Get-Location).Path }
}
$Repo = (Resolve-Path -LiteralPath $Repo).Path

$LogPath  = Join-Path $Repo '.git\auto-sync.log'
$PidPath  = Join-Path $Repo '.git\auto-sync.pid'

# ---------------------------------------------------------------- helpers ----

function Write-Log {
    param([string] $Message, [string] $Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    try { Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8 } catch { }
    Write-Host $line
}

function Resolve-Git {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($candidate in @(
            'C:\Program Files\Git\cmd\git.exe',
            'C:\Program Files (x86)\Git\cmd\git.exe',
            (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe'))) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw 'git executable not found. Install Git or add it to PATH.'
}

function Invoke-Git {
    param([string[]] $GitArgs)
    $out = & $script:Git @GitArgs 2>&1
    [pscustomobject]@{
        Code   = $LASTEXITCODE
        Output = (($out | Out-String).Trim())
    }
}

function Get-TreeStatus {
    $out = & $script:Git status --porcelain 2>$null
    ($out | Out-String).Trim()
}

# ------------------------------------------------------------ stop mode -----

if ($Stop) {
    if (Test-Path -LiteralPath $PidPath) {
        $target = (Get-Content -LiteralPath $PidPath -Raw).Trim()
        try {
            Stop-Process -Id ([int]$target) -Force -ErrorAction Stop
            Write-Host "[auto-sync] stopped (pid $target)"
        } catch {
            Write-Host "[auto-sync] pid $target is not running"
        }
        Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host '[auto-sync] not running (no pid file)'
    }
    return
}

# ---------------------------------------------------------------- startup ---

$script:Git = Resolve-Git
Set-Location -LiteralPath $Repo

if (-not (Test-Path -LiteralPath (Join-Path $Repo '.git'))) {
    throw "Not a git repository: $Repo"
}

# Refuse a second daemon so two loops never race over the index.
if (-not $Once -and (Test-Path -LiteralPath $PidPath)) {
    $existing = (Get-Content -LiteralPath $PidPath -Raw).Trim()
    if ($existing -and (Get-Process -Id ([int]$existing) -ErrorAction SilentlyContinue)) {
        Write-Host "[auto-sync] already running as pid $existing - use -Stop first"
        return
    }
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
}

$currentBranch = (& $script:Git rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
if ($currentBranch -ne $Branch) {
    Write-Log "currently on '$currentBranch', requested '$Branch' - using the requested branch name for push only" 'WARN'
}

if (-not $Once) {
    Set-Content -LiteralPath $PidPath -Value $PID -Encoding ASCII
}

Write-Log ("auto-sync started (pid {0}) repo={1} branch={2} quiet={3}s poll={4}s once={5}" -f `
        $PID, $Repo, $Branch, $QuietSeconds, $PollSeconds, [bool]$Once)

# ------------------------------------------------------------- operations ---

function Wait-ForQuiet {
    param([string] $Initial)
    $snapshot   = $Initial
    $lastChange = Get-Date
    while ($true) {
        Start-Sleep -Seconds $PollSeconds
        $now = Get-TreeStatus
        if ($now -ne $snapshot) {
            $snapshot    = $now
            $lastChange  = Get-Date
            continue
        }
        if (-not $now) { return $null }                    # work reverted / discarded
        if (((Get-Date) - $lastChange).TotalSeconds -ge $QuietSeconds) { return $now }
    }
}

function Save-Snapshot {
    param([string] $Status)
    $touched = ($Status -split "`r?`n" | Where-Object { $_.Trim() }).Count

    $add = Invoke-Git @('add', '-A')
    if ($add.Code -ne 0) {
        Write-Log "git add failed: $($add.Output)" 'ERR'
        return $false
    }

    $staged = (& $script:Git diff --cached --name-only | Measure-Object).Count
    if ($staged -eq 0) {
        Write-Log 'changes resolved themselves (nothing staged)' 'SKIP'
        return $false
    }

    $stamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $message = "chore(auto-sync): snapshot $stamp ($staged file$(if ($staged -ne 1) { 's' }))"
    $commit  = Invoke-Git @('commit', '-m', $message)
    if ($commit.Code -ne 0) {
        Write-Log "commit failed: $($commit.Output)" 'ERR'
        return $false
    }
    Write-Log "committed $staged file(s) from $touched change(s): $message" 'OK'
    return $true
}

function Push-Snapshot {
    $push = Invoke-Git @('push', '-u', $Remote, "HEAD:$Branch")
    if ($push.Code -eq 0) {
        Write-Log 'pushed to remote' 'OK'
        return $true
    }

    Write-Log "push failed, trying rebase: $($push.Output)" 'WARN'
    $pull = Invoke-Git @('pull', '--rebase', '--autostash', $Remote, $Branch)
    if ($pull.Code -ne 0) {
        & $script:Git rebase --abort 2>$null | Out-Null
        & $script:Git merge --abort 2>$null | Out-Null
        Write-Log "rebase failed, commit kept locally: $($pull.Output)" 'ERR'
        return $false
    }

    $retry = Invoke-Git @('push', '-u', $Remote, "HEAD:$Branch")
    if ($retry.Code -eq 0) {
        Write-Log 'pushed to remote after rebase' 'OK'
        return $true
    }
    Write-Log "push still failing, will retry: $($retry.Output)" 'ERR'
    return $false
}

# ---------------------------------------------------------------- main loop -

$pendingPush  = $false
$lastAttempt  = Get-Date '2000-01-01'

try {
    while ($true) {
        $lock = Join-Path $Repo '.git\index.lock'
        if (Test-Path -LiteralPath $lock) {
            Write-Log 'index.lock present (another git command running) - waiting' 'WAIT'
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        $status = Get-TreeStatus

        if (-not $status) {
            if ($pendingPush -and ((Get-Date) - $lastAttempt).TotalSeconds -ge $PushRetrySeconds) {
                $lastAttempt = Get-Date
                if (Push-Snapshot) { $pendingPush = $false }
            }
            if ($Once) { break }
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        Write-Log ("{0} change(s) detected - waiting for {1}s of quiet" -f `
                ($status -split "`r?`n").Count, $QuietSeconds)

        $settled = Wait-ForQuiet -Initial $status
        if (-not $settled) {
            Write-Log 'working tree went clean before snapshot - skipped' 'SKIP'
            if ($Once) { break }
            continue
        }

        if (Save-Snapshot -Status $settled) {
            $lastAttempt = Get-Date
            $pendingPush = -not (Push-Snapshot)
        }

        if ($Once) { break }
    }
} finally {
    if (-not $Once) {
        Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
    }
    Write-Log 'auto-sync stopped'
}
