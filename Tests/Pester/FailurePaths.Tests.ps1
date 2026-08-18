Describe 'Failure paths' {

    It 'throws after retry exhaustion when file is exclusively locked' {
        $path = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.log')
        New-Item -Path $path -ItemType File -Force | Out-Null

        # Use a directory path to force failure when trying to open as a file
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        New-Item -Path $path -ItemType Directory | Out-Null
        try {
            { Append-LogAtomic -Path $path -Value 'x' -MaxRetries 1 -RetryDelayMs 1 } | Should Throw
        } finally {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'throws for malformed LogContext in Resolve-LogPath' {
        # Missing both LogContext and LogPath should throw
        { Write-LogInfo -Message 'm' } | Should Throw
    }

    It 'returns false when SMTP client Send throws' {
        $log = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.log')
        Set-Content -Path $log -Value 'body'

        Mock -CommandName New-Object -MockWith {
            $client = [pscustomobject]@{ Timeout = 0 }
            $null = $client | Add-Member -MemberType ScriptMethod -Name Send -Value { param($from,$to,$subject,$body) throw 'SMTP failure' } -PassThru
            $null = $client | Add-Member -MemberType ScriptMethod -Name Dispose -Value { } -PassThru
            return $client
        } -ModuleName PSLogging2

        $result = Send-Log -SMTPServer 'smtp.example' -LogPath $log -EmailFrom 'a@b' -EmailTo 'c@d' -EmailSubject 's'
        $result | Should Be $false

        Assert-MockCalled -CommandName New-Object -Times 1
        Remove-Item -Path $log -Force -ErrorAction SilentlyContinue
    }

}
