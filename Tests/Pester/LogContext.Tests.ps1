Describe "LogContext prototype" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_ctx"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "Start-Log -ReturnContext and Write-LogInfo -LogContext write to the file" {
        $scriptPath = Join-Path $script:tempDir 'write_with_context.ps1'
        $logDir = Join-Path $script:tempDir 'logs_ctx'
        $scriptLines = @(
"`$moduleRoot = (Resolve-Path (Join-Path `$PSScriptRoot '..\\..\\..')).Path",
"Import-Module (Join-Path `$moduleRoot 'PSLogging2.psm1') -Force",
"`$ctx = Start-Log -Style Simple -LogDir '$logDir' -Title 'Pester Context Test' -ReturnContext",
"Write-LogInfo -Message 'context message' -LogContext `$ctx"
        )
        $scriptLines | Set-Content -Path $scriptPath -Encoding UTF8

        $p = Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File', $scriptPath -PassThru -Wait
        $logFile = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { $_.Extension -eq '.log' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw
        ($content -match 'context message') | Should Be $true
    }

    AfterAll {
        # keep artifacts for inspection
    }
}
