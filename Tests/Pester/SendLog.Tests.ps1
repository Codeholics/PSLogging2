Describe "Send-Log with LogContext" {
    BeforeAll {
        $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $script:tempDir = Join-Path -Path $root -ChildPath "temp_send"
        if (-Not (Test-Path $script:tempDir)) { New-Item -Path $script:tempDir -ItemType Directory | Out-Null }

        # Define a lightweight fake SmtpClient class to avoid network IO
        $code = @'
using System;
public class FakeSmtpClient : IDisposable {
    public int Timeout;
    public FakeSmtpClient(string host) { }
    public void Send(string from, string to, string subject, string body) { }
    public void Dispose() { }
}
'@
        Add-Type -TypeDefinition $code -Language CSharp

        Import-Module (Join-Path -Path (Resolve-Path (Join-Path $root '..\..')).Path -ChildPath 'PSLogging2.psm1') -Force
    }

    It "uses a fake SMTP client and returns true" {
        $logDir = Join-Path $script:tempDir 'logs'
        if (-Not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

        # Start log and get context
        $ctx = Start-Log -Style Simple -LogDir $logDir -Title 'SendLog Test' -ReturnContext

        # Mock New-Object inside the module scope so Send-Log does not create a real SMTP client.
        Mock -CommandName New-Object -ModuleName PSLogging2 -ParameterFilter { $TypeName -eq 'Net.Mail.SmtpClient' } -MockWith {
            [FakeSmtpClient]::new($ArgumentList[0])
        }

        $result = Send-Log -SMTPServer 'dummy' -LogContext $ctx -EmailFrom 'me@example.com' -EmailTo 'you@example.com' -EmailSubject 'test'
        $result | Should Be $true
    }

    It "attaches the file when over -MaxInlineSizeMB" {
        $log = Join-Path $script:tempDir 'big.log'
        # create a small file but force attachment by setting threshold to 0
        Set-Content -Path $log -Value 'body'

        $global:sentWithAttachment = $false

        Mock -CommandName New-Object -ModuleName PSLogging2 -ParameterFilter { $TypeName -eq 'Net.Mail.SmtpClient' } -MockWith {
            $client = [pscustomobject]@{ Timeout = 0 }
            $null = $client | Add-Member -MemberType ScriptMethod -Name Send -Value { param($arg) if ($arg -is [System.Net.Mail.MailMessage]) { $global:sentWithAttachment = $true } } -PassThru
            $null = $client | Add-Member -MemberType ScriptMethod -Name Dispose -Value { } -PassThru
            return $client
        }

        $result = Send-Log -SMTPServer 'dummy' -LogPath $log -EmailFrom 'me@example.com' -EmailTo 'you@example.com' -EmailSubject 'attach' -MaxInlineSizeMB 0
        $result | Should Be $true
        $global:sentWithAttachment | Should Be $true

        Remove-Item -Path $log -Force -ErrorAction SilentlyContinue
    }

    AfterAll {
        # keep artifacts for inspection
    }
}
