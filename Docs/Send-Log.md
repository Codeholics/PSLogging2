# Send-Log Usage

`Send-Log` delivers a completed PSLogging2 log over SMTP. It returns `$true` when the SMTP send succeeds. By default, delivery errors write an error record and return `$false`; use `-ThrowOnFailure` when email delivery is required for the calling automation to succeed.

## Requirements

- A reachable SMTP server that accepts the supplied sender and recipients.
- A completed log identified by either `-LogContext` or `-LogPath`.
- `-SMTPServer`, `-EmailFrom`, `-EmailTo`, and `-EmailSubject`.

`Send-Log` currently uses .NET `SmtpClient`. Modern authentication, SMTP security settings, and Microsoft Graph delivery are not implemented yet; see [SendLog-Auth-Modernization.md](SendLog-Auth-Modernization.md) for the approved roadmap.

## Basic Delivery

Use the `LogContext` returned from `Start-Log -ReturnContext` when the same script owns the logging lifecycle.

```powershell
Import-Module .\PSLogging2.psm1 -Force

$ctx = Start-Log -Style Standard -LogDir .\log -Title 'Inventory' -ReturnContext
Write-LogInfo -Message 'Inventory completed.' -LogContext $ctx
Stop-Log -LogContext $ctx

$sent = Send-Log `
    -SMTPServer 'smtp.example.com' `
    -LogContext $ctx `
    -EmailFrom 'automation@example.com' `
    -EmailTo 'operations@example.com' `
    -EmailSubject 'Inventory log'

if (-not $sent) {
    Write-Error 'The inventory log was not delivered.'
}
```

Use `-LogPath` when sending a log produced by another script or a previous run.

```powershell
Send-Log `
    -SMTPServer 'smtp.example.com' `
    -LogPath 'C:\Logs\Inventory\2026-08-22.log' `
    -EmailFrom 'automation@example.com' `
    -EmailTo 'operations@example.com' `
    -EmailSubject 'Inventory log'
```

## Recipients

`-EmailTo` accepts either a comma-separated string or an array. Whitespace around comma-separated addresses is ignored.

```powershell
# Comma-separated string
-EmailTo 'operations@example.com, oncall@example.com'

# Array
-EmailTo @('operations@example.com', 'oncall@example.com')
```

## Inline Body and Attachments

Logs up to `-MaxInlineSizeMB` are sent as the plain-text email body. The default is 5 MB. Larger logs are attached instead.

```powershell
# Send logs larger than 2 MB as an attachment.
Send-Log `
    -SMTPServer 'smtp.example.com' `
    -LogPath .\log\run.log `
    -EmailFrom 'automation@example.com' `
    -EmailTo 'operations@example.com' `
    -EmailSubject 'Run log' `
    -MaxInlineSizeMB 2
```

Set `-MaxInlineSizeMB 0` to force attachment delivery for a non-empty log.

## Redacting Sensitive Content

Use one or more regular expressions with `-RedactRegex` to replace matching text in the sent copy. The original log remains unchanged by default. The default replacement is `***REDACTED***`; customize it with `-RedactionMask`.

```powershell
Send-Log `
    -SMTPServer 'smtp.example.com' `
    -LogPath .\log\run.log `
    -EmailFrom 'automation@example.com' `
    -EmailTo 'security@example.com' `
    -EmailSubject 'Sanitized run log' `
    -RedactRegex 'password=\S+', 'token=\S+' `
    -RedactionMask '[REDACTED]'
```

When redaction is requested, `Send-Log` creates a temporary sanitized copy for delivery and removes it after the attempt. Use `-RedactInPlace` only when replacing matching content in the original log is intentional and acceptable.

```powershell
Send-Log `
    -SMTPServer 'smtp.example.com' `
    -LogPath .\log\run.log `
    -EmailFrom 'automation@example.com' `
    -EmailTo 'security@example.com' `
    -EmailSubject 'Permanently sanitized run log' `
    -RedactRegex 'token=\S+' `
    -RedactInPlace
```

Invalid regular expressions cause the send to fail. The source log is not modified unless `-RedactInPlace` is specified.

## Required Delivery

Add `-ThrowOnFailure` when an email delivery failure should be handled by `try`/`catch` or fail the surrounding job.

```powershell
try {
    Send-Log `
        -SMTPServer 'smtp.example.com' `
        -LogPath .\log\run.log `
        -EmailFrom 'automation@example.com' `
        -EmailTo 'operations@example.com' `
        -EmailSubject 'Required run log' `
        -ThrowOnFailure
} catch {
    Write-Error "Required log delivery failed: $($_.Exception.Message)"
    throw
}
```

## Current Behavior Summary

| Behavior | Current implementation |
| --- | --- |
| Transport | SMTP via `System.Net.Mail.SmtpClient` |
| Send timeout | 30 seconds |
| Inline threshold | 5 MB by default; configurable with `-MaxInlineSizeMB` |
| Large logs | Sent as a file attachment |
| Redaction default | Temporary sanitized copy; source log unchanged |
| Failure default | Writes an error and returns `$false` |
| Terminating failure | `-ThrowOnFailure` |
| Modern authentication | Not yet implemented |
