Describe "TimestampPosition validation and formatting" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_timestamp"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }
    }

    It "writes timestamps in the expected positions for info, warning, and error entries" {
        $logDir = Join-Path $script:tempDir ([guid]::NewGuid().ToString('N'))
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null

        $ctx = Start-Log -Style Simple -LogDir $logDir -Title 'Timestamp Test' -ReturnContext

        Write-LogInfo -Message 'info front' -TimestampPosition Front -LogContext $ctx
        Write-LogWarning -Message 'warning back' -TimestampPosition Back -LogContext $ctx
        Write-LogError -Message 'error plain' -TimestampPosition None -LogContext $ctx

        $logFile = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { $_.Extension -eq '.log' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw

        $content | Should Match '(?m)^- \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] info front\r?$'
        $content | Should Match '(?m)^WARNING: warning back \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]\r?$'
        $content | Should Match '(?m)^ERROR: error plain\r?$'
    }

    It "uses None as the default timestamp position" {
        $logDir = Join-Path $script:tempDir ([guid]::NewGuid().ToString('N'))
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null

        $ctx = Start-Log -Style Simple -LogDir $logDir -Title 'Timestamp Default Test' -ReturnContext

        Write-LogInfo -Message 'default none' -LogContext $ctx

        $logFile = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { $_.Extension -eq '.log' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $content = Get-Content -Path $logFile.FullName -Raw

        $content | Should Match '(?m)^- default none\r?$'
        $content -match '(?m)^- \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] default none\r?$' | Should Be $false
    }

    It "rejects invalid TimestampPosition values across writer functions" {
        $logDir = Join-Path $script:tempDir ([guid]::NewGuid().ToString('N'))
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null

        $ctx = Start-Log -Style Simple -LogDir $logDir -Title 'Timestamp Validation Test' -ReturnContext

        $infoThrew = $false
        try { Write-LogInfo -Message 'bad info' -TimestampPosition Side -LogContext $ctx -ErrorAction Stop } catch { $infoThrew = $true }
        $infoThrew | Should Be $true

        $warningThrew = $false
        try { Write-LogWarning -Message 'bad warning' -TimestampPosition Side -LogContext $ctx -ErrorAction Stop } catch { $warningThrew = $true }
        $warningThrew | Should Be $true

        $errorThrew = $false
        try { Write-LogError -Message 'bad error' -TimestampPosition Side -LogContext $ctx -ErrorAction Stop } catch { $errorThrew = $true }
        $errorThrew | Should Be $true
    }
}