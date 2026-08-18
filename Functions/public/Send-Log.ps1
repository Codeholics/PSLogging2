<#
.SYNOPSIS
    Send the completed log file via SMTP.

.DESCRIPTION
    Reads the contents of a log file and sends it as the email body using
    the specified SMTP server and addressing parameters.

.PARAMETER SMTPServer
    FQDN or address of the SMTP server to use for sending the email.

.PARAMETER LogPath
    Full path to the log file to include in the email body. Optional when using `-LogContext`.

.PARAMETER EmailFrom
    Email address to use as the sender.

.PARAMETER EmailTo
    Comma-separated list of recipient email addresses.

.PARAMETER EmailSubject
    Subject line for the outgoing email.

.EXAMPLE
    Send-Log -SMTPServer 'smtp.example.com' -LogPath .\log\today.log -EmailFrom 'me@x' -EmailTo 'you@x' -EmailSubject 'Run log'

.NOTES
    This function uses .NET's `System.Net.Mail.SmtpClient` and does not
    support modern authentication flows (OAuth). Use only with trusted SMTP
    servers or adjust to your environment.
#>
function Send-Log {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)][string]$SMTPServer,

        [object]
        $LogContext,
        [string]
        $LogPath,
        [Parameter(Mandatory=$true)][string]$EmailFrom,
        [Parameter(Mandatory=$true)][string]$EmailTo,
        [Parameter(Mandatory=$true)][string]$EmailSubject
    )

    # Resolve LogPath from a single LogContext object if provided
    if ($null -ne $LogContext) {
        if ($LogContext -is [System.Collections.IDictionary] -and $LogContext.ContainsKey('LogPath')) {
            $LogPath = $LogContext['LogPath']
        } elseif ($LogContext -ne $null -and ($LogContext.PSObject.Properties.Name -contains 'LogPath')) {
            $LogPath = $LogContext.LogPath
        } else {
            throw "Send-Log requires a single LogContext object with a LogPath property or an explicit -LogPath."
        }
    }

    if (-not $LogPath) {
        Write-Error "Send-Log requires -LogPath or a -LogContext containing LogPath"
        return $false
    }

    if (-not (Test-Path $LogPath)) {
        Write-Error "Log file not found: $LogPath"
        return $false
    }

    Try {
        $sBody = Get-Content -Path $LogPath -Raw
        $oSmtp = New-Object Net.Mail.SmtpClient($SMTPServer)
        # set timeout before sending
        $oSmtp.Timeout = 30000
        $oSmtp.Send($EmailFrom, $EmailTo, $EmailSubject, $sBody)
        return $true
    } Catch {
        Write-Error "Failed to send log email: $($_)"
        return $false
    } Finally {
        if ($oSmtp) { $oSmtp.Dispose() }
    }
}