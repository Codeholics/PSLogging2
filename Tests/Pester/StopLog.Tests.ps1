Describe "Stop-Log and Write-LogError integration" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "writes a footer when Stop-Log is called (NoExit)" {
        $scriptPath = Join-Path $script:tempDir 'stoplog_noexit.ps1'
        $logDir = Join-Path $script:tempDir 'logs'
        $scriptLines = @(
    "`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\\..\\..')).Path",
    "Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force",
    "`$ctx = Start-Log -Style Simple -LogDir '$logDir' -Title 'Pester StopLog Test' -ToScreen -ReturnContext",
    "Write-LogInfo -Message 'step' -LogContext `$ctx",
    "Stop-Log -LogContext `$ctx -NoExit",
    "Exit 0"
        )
        $scriptLines | Set-Content -Path $scriptPath -Encoding UTF8

        $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File', $scriptPath -PassThru -Wait
        $logFile = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { $_.Extension -eq '.log' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw
        ($content -match 'Finished at:') | Should Be $true
        ($content -match 'Total Execution Time:') | Should Be $true
    }

    It "writes a footer when Write-LogError -ExitGracefully is used" {
        $scriptPath = Join-Path $script:tempDir 'write_log_error_exit.ps1'
        $logDir = Join-Path $script:tempDir 'logs2'
        $scriptLines = @(
    "`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\\..\\..')).Path",
    "Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force",
    "`$ctx = Start-Log -Style Simple -LogDir '$logDir' -Title 'Pester WriteLogError Test' -ToScreen -ReturnContext",
    "Write-LogError -Message 'fatal' -TimestampPosition Back -ExitGracefully -LogContext `$ctx"
        )
        $scriptLines | Set-Content -Path $scriptPath -Encoding UTF8

        $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File', $scriptPath -PassThru -Wait
        $logFile = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { $_.Extension -eq '.log' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw
        ($content -match 'Finished at:') | Should Be $true
        ($content -match 'Total Execution Time:') | Should Be $true
    }

    AfterAll {
        # optional cleanup - keep artifacts for inspection
    }
}
