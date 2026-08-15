<#
.SYNOPSIS
    Simple concurrent-write test for Daily-mode log appends.

.DESCRIPTION
    Spawns multiple background jobs that concurrently append lines to the
    same daily log file using `Append-LogAtomic`. Verifies that the final
    line count matches expected value and that no write exceptions were
    thrown by the jobs.
#>

param(
    [int]$Jobs = 8,
    [int]$LinesPerJob = 250
)

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$functionsDir = (Resolve-Path (Join-Path $scriptDir '..\Functions')).Path
$testLogDir = Join-Path $scriptDir 'temp-log'
if (-not (Test-Path $testLogDir)) { New-Item -Path $testLogDir -ItemType Directory | Out-Null }

$date = Get-Date -Format 'yyyy-MM-dd'
$logPath = Join-Path $testLogDir "$date.log"

Write-Host "Using functions dir: $functionsDir"
Write-Host "Log path: $logPath"

# Ensure file exists
if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType File | Out-Null }

$jobList = @()
for ($i=0; $i -lt $Jobs; $i++) {
    $job = Start-Job -ArgumentList $functionsDir, $logPath, $LinesPerJob, $i -ScriptBlock {
        param($functionsDir, $logPath, $lines, $id)
        # Dot-source the helper that contains Append-LogAtomic
        . (Join-Path $functionsDir 'Log-IO.ps1')
        for ($j=0; $j -lt $lines; $j++) {
            try {
                Append-LogAtomic -Path $logPath -Value "Job:$id Line:$j" -MaxRetries 10 -RetryDelayMs 300 | Out-Null
            } catch {
                Write-Error "Job $id failed to write: $($_)"; throw
            }
        }
        return @{JobId=$id; Lines=$lines}
    }
    $jobList += $job
}

# Wait and collect results
Write-Host "Waiting for jobs to complete..."
Wait-Job -Job $jobList
$errors = $false
foreach ($j in $jobList) {
    $state = (Get-Job -Id $j.Id).State
    if ($state -ne 'Completed') { Write-Host "Job $($j.Id) ended with state $state"; $errors = $true }
    $outs = Receive-Job -Job $j -ErrorAction SilentlyContinue
    if ($outs -and $outs -is [System.Array]) { } # ignore
}

if ($errors) {
    Write-Host "One or more jobs failed. Inspect job output with Get-Job / Receive-Job." -ForegroundColor Red
    exit 2
}

# Verify line count
$lines = (Get-Content -Path $logPath -ErrorAction Stop | Measure-Object -Line).Lines
$expected = $Jobs * $LinesPerJob
Write-Host "Wrote $lines lines; expected at least $expected lines"
if ($lines -lt $expected) {
    Write-Host "FAIL: fewer lines than expected" -ForegroundColor Red
    exit 3
} else {
    Write-Host "PASS: concurrent appends succeeded" -ForegroundColor Green
    exit 0
}
