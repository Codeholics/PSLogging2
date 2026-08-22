Describe 'Failure paths' {

    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        Import-Module (Join-Path -Path (Resolve-Path (Join-Path $root '..\..')).Path -ChildPath 'PSLogging2.psm1') -Force
    }

    It 'throws when log directory creation fails' {
        $tmpDir = Join-Path $env:TEMP ([guid]::NewGuid().ToString())

        Mock -CommandName New-Item -ModuleName PSLogging2 -ParameterFilter { $ItemType -eq 'Directory' } -MockWith { throw 'filesystem failure' }

        { Start-Log -Style Simple -LogDir $tmpDir -Title 'fail' -ErrorAction Stop } | Should Throw

        Assert-MockCalled -CommandName New-Item -ModuleName PSLogging2 -Times 1
    }

    It 'throws after retry exhaustion when file is exclusively locked' {
        $path = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.log')
        $module = Get-Module PSLogging2

        # Hold an exclusive handle so every atomic-append attempt fails.
        $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        try {
            $exception = & $module {
                param($targetPath)
                try {
                    Append-LogAtomic -Path $targetPath -Value 'x' -MaxRetries 3 -RetryDelayMs 1
                } catch {
                    $_
                }
            } $path

            $exception | Should Not BeNullOrEmpty
        } finally {
            $stream.Dispose()
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        }
    }

    It 'throws for a malformed LogContext in a writer' {
        $context = [pscustomobject]@{ Invalid = 'context' }
        $exception = $null

        try {
            Write-LogInfo -Message 'm' -LogContext $context -ErrorAction Stop
        } catch {
            $exception = $_
        }

        $exception | Should Not BeNullOrEmpty
        $exception.Exception.Message | Should Match 'Invalid or missing LogPath'
    }

    It 'throws when a writer cannot append to the log' {
        $path = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.log')
        $exception = $null
        New-Item -Path $path -ItemType Directory | Out-Null

        try {
            Write-LogError -Message 'm' -LogPath $path -ErrorAction Stop
        } catch {
            $exception = $_
        } finally {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }

        $exception | Should Not BeNullOrEmpty
        $exception.Exception.Message | Should Match 'Failed to append error to log'
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

        Assert-MockCalled -CommandName New-Object -ModuleName PSLogging2 -Times 1
        Remove-Item -Path $log -Force -ErrorAction SilentlyContinue
    }

    It 'throws when SMTP client Send throws and -ThrowOnFailure is specified' {
        $log = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.log')
        Set-Content -Path $log -Value 'body'

        Mock -CommandName New-Object -MockWith {
            $client = [pscustomobject]@{ Timeout = 0 }
            $null = $client | Add-Member -MemberType ScriptMethod -Name Send -Value { param($from,$to,$subject,$body) throw 'SMTP failure' } -PassThru
            $null = $client | Add-Member -MemberType ScriptMethod -Name Dispose -Value { } -PassThru
            return $client
        } -ModuleName PSLogging2

        { Send-Log -SMTPServer 'smtp.example' -LogPath $log -EmailFrom 'a@b' -EmailTo 'c@d' -EmailSubject 's' -ThrowOnFailure } | Should Throw

        Assert-MockCalled -CommandName New-Object -ModuleName PSLogging2 -Times 1
        Remove-Item -Path $log -Force -ErrorAction SilentlyContinue
    }

}
