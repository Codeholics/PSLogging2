Describe "Daily log header initialization race" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_daily_header"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "only one header block is created when multiple processes start the same daily log" {
        $jobs = 8
        $runId = [guid]::NewGuid().ToString('N')
        $logDir = Join-Path $script:tempDir "logs_$runId"
        if (-Not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

        $scriptPaths = @()
        for ($j = 1; $j -le $jobs; $j++) {
            $scriptPath = Join-Path $script:tempDir "initjob_$j.ps1"
            $scriptLines = @(
                "`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\\..\\..')).Path",
                "Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force",
                "Start-Log -Style Daily -LogDir '$logDir' -Title 'Daily Header Race Test' -ReturnContext | Out-Null",
                "Stop-Log -LogDir '$logDir' | Out-Null"
            )
            $scriptLines | Set-Content -Path $scriptPath -Encoding UTF8
            $scriptPaths += $scriptPath
        }

        $procs = @()
        foreach ($sp in $scriptPaths) {
            $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$sp -PassThru
            $procs += $p
        }

        foreach ($proc in $procs) {
            if (-not $proc.HasExited) { $proc.WaitForExit() }
        }

        $logFile = Get-ChildItem -Path $logDir -Recurse -Filter '*.log' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw

        # Count header blocks by matching the header title line to avoid counting footer/asterisk lines
        $titleMatches = ($content -split "`r?`n") | Where-Object { $_ -match 'Daily Header Race Test' }
        $titleMatches.Count | Should Be 1

        # Ensure each process exited successfully
        foreach ($proc in $procs) { $proc.ExitCode | Should Be 0 }
    }

    AfterAll {
        # keep artifacts for inspection
    }
}
