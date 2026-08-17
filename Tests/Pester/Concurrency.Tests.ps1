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
                "for (`$i = 1; `$i -le $linesPerJob; `$i++) { Write-LogInfo -Message 'run $runId job$j line `$i' -LogContext `$ctx }",
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
        $matchCount = ([regex]::Matches($content, [regex]::Escape("run $runId") + ' job\d+ line')).Count
        $matchCount | Should Be ($jobs * $linesPerJob)
    }

    AfterAll {
        # keep artifacts for inspection
    }
}
