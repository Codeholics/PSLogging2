Describe "Environment: Network share write validation" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:share = $env:PSLOG_TEST_SHARE
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_env"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "writes to a provided network share when configured" {
        if (-not $script:share) { Skip "Set PSLOG_TEST_SHARE environment variable to a UNC path (e.g. \\\\host\\share) to run this test." }

        $logDir = Join-Path $script:share "pslogging_test_$(Get-Random)"
        try {
            $ctx = Start-Log -Style Daily -LogDir $logDir -Title 'Network Share Test' -ReturnContext
            Write-LogInfo -Message 'network share write test' -LogContext $ctx
            Stop-Log -LogContext $ctx

            # Verify file exists and contains header
            $file = Get-ChildItem -Path $logDir -Recurse -Filter '*.log' -File | Select-Object -First 1
            $file | Should -Not -BeNullOrEmpty
            (Get-Content -Path $file.FullName -Raw) | Should -Match 'Network Share Test'
        } finally {
            # No automated cleanup of remote share
        }
    }

    AfterAll { }
}
