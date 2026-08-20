Describe "Concurrent writes with separate LogContext instances" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_concurrency"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "multiple processes can append to the same daily log using separate contexts" {
        $jobs = 6
        $linesPerJob = 200
        $runId = [guid]::NewGuid().ToString('N')
        $logDir = Join-Path $script:tempDir "logs_$runId"
        if (-Not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

        $scriptPaths = @()
        for ($j = 1; $j -le $jobs; $j++) {
            $scriptPath = Join-Path $script:tempDir "job_$j.ps1"
            $scriptLines = @(
                "`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\\..\\..')).Path",
                "Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force",
                "`$ctx = Start-Log -Style Daily -LogDir '$logDir' -Title 'Concurrency Test' -ReturnContext",
                "for (`$i = 1; `$i -le $linesPerJob; `$i++) { Write-LogInfo -Message `"run $runId job$j line `$i`" -LogContext `$ctx }",
                "Stop-Log -LogContext `$ctx"
            )
            $scriptLines | Set-Content -Path $scriptPath -Encoding UTF8
            $scriptPaths += $scriptPath
        }

        $procs = @()
        foreach ($sp in $scriptPaths) {
            $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$sp -PassThru
            $procs += $p
        }

        # Wait for all processes to finish
        foreach ($proc in $procs) {
            if (-not $proc.HasExited) {
                $proc.WaitForExit()
            }
        }

        # Find the daily log file
        $logFile = Get-ChildItem -Path $logDir -Recurse -Filter '*.log' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw

        # Count occurrences of job lines
        # Collect all lines that mention this run id
        $lines = ($content -split "`r?`n") | Where-Object { $_ -match [regex]::Escape("run $runId") }

        # Ensure total count matches expectation
        $lines.Count | Should Be ($jobs * $linesPerJob)

        # Ensure every full message line is unique (no duplicates)
        $uniqueLines = $lines | Sort-Object -Unique
        $uniqueLines.Count | Should Be ($jobs * $linesPerJob)

        # Detect malformed lines that mention the runId but don't include the expected keywords
        $malformed = $lines | Where-Object { -not ($_ -match 'job') -or -not ($_ -match 'line') }
        $malformed.Count | Should Be 0

        # Header should exist exactly once (initial header block contains the title line)
        $headerCount = ([regex]::Matches($content, '\*{99}').Count)
        ($headerCount -ge 1) | Should Be $true

        # Footer lines contain the 'Finished at:' marker; expect one per process that called Stop-Log
        $footerCount = ([regex]::Matches($content, 'Finished at:').Count)
        $footerCount | Should Be $jobs

        # Verify processes exited successfully
        foreach ($proc in $procs) { $proc.ExitCode | Should Be 0 }
    }

    AfterAll {
        # keep artifacts for inspection
    }
}
