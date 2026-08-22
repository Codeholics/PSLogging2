param(
    [int]$Jobs = 10,
    [int]$LinesPerJob = 200
)

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$tempDir = Join-Path -Path $root -ChildPath "temp_stress"
if (-Not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory | Out-Null }

$runId = [guid]::NewGuid().ToString('N')
$logDir = Join-Path $tempDir "logs_$runId"
if (-Not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

$scriptPaths = @()
for ($j = 1; $j -le $Jobs; $j++) {
    $scriptPath = Join-Path $tempDir "stress_job_$j.ps1"
    $scriptContent = @"
`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force
`$ctx = Start-Log -Style Daily -LogDir '$logDir' -Title 'Stress Test' -ReturnContext
for (`$i = 1; `$i -le $LinesPerJob; `$i++) { Write-LogInfo -Message ('stress $runId job$j line ' + `$i) -LogContext `$ctx }
Stop-Log -LogContext `$ctx
"@
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    $scriptPaths += $scriptPath
}

Write-Host "Starting stress run: $Jobs jobs x $LinesPerJob lines (expected $($Jobs * $LinesPerJob) entries)" -ForegroundColor Cyan

$procs = @()
foreach ($sp in $scriptPaths) {
    $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$sp -PassThru
    $procs += $p
}

# Wait for processes
foreach ($proc in $procs) {
    if (-not $proc.HasExited) { $proc.WaitForExit() }
}

# Locate the daily log
$logFile = Get-ChildItem -Path $logDir -Recurse -Filter '*.log' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $logFile) { Write-Error "No log file found in $logDir"; exit 2 }

$content = Get-Content -Path $logFile.FullName -Raw
$lines = ($content -split "`r?`n") | Where-Object { $_ -match [regex]::Escape("stress $runId") }

$expected = $Jobs * $LinesPerJob
Write-Host "Found $($lines.Count) stress lines; expected $expected" -ForegroundColor Cyan

# Verify counts and process exit codes
$allExitedZero = $true
foreach ($proc in $procs) { if ($proc.ExitCode -ne 0) { $allExitedZero = $false } }

if ($lines.Count -ne $expected) {
    Write-Error "Mismatch: expected $expected lines but found $($lines.Count)"
    exit 3
}

if (-not $allExitedZero) {
    Write-Error "One or more stress processes exited non-zero"
    exit 4
}

Write-Host "Stress test succeeded: $($lines.Count) entries written." -ForegroundColor Green
exit 0
