# PSLogging2

PSLogging2 is a lightweight PowerShell logging module that provides simple
file-based logging suitable for scripts and automation. It supports three
naming styles, configurable timestamps, and simple email delivery of logs.

## Features

- Create per-run, per-day, or nested timestamped logs (`Simple`, `Daily`, `Standard`).
- Informational, Warning, and Error helpers: `Write-LogInfo`, `Write-LogWarning`, `Write-LogError`.
- Optional timestamp placement (front or end) via `-TimeStampFront` and `-TimeStampBack`.
- Daily-mode run consolidation: multiple runs can be written to a single daily file with a run separator.
- Optional `-DisableDailySeparator` to opt out of run separators.
- `Send-Log` to email the completed log via SMTP.

## Installation

Copy the `PSLogging2` folder into one of your PowerShell module paths or import directly:

```powershell
Import-Module 'PSLogging2'
```

## Basic Usage

Start logging for a run (simple per-run file):

```powershell
Start-Log -Style Simple -LogDir .\log -Title 'MyScript' -ToScreen -Version '1.0'
Write-LogInfo -Message 'Started' -TimeStampBack
Write-LogWarning -Message 'Deprecated config' -TimeStampFront
Write-LogError -Message 'Fatal error' -TimeStampBack -ExitGracefully
Stop-Log
```

Standard mode (nested year/month/run files):

```powershell
Start-Log -Style Standard -LogDir .\log -Title 'MyScript' -ToScreen -Version '1.0'
Write-LogInfo -Message 'Started' -TimeStampBack
Stop-Log
```

Behavior: `Standard` creates a nested folder structure under `LogDir` using the
year and year-month (for example `log\2026\2026-08`) and names the log file
with a timestamp (`2026-08-11_222409.log`). Use `Standard` when you want an
organized archive of runs grouped by month and year.

Daily mode (all runs share a single file for the day):

```powershell
Start-Log -Style Daily -LogDir .\log -Title 'MyScript'
Write-LogInfo -Message 'Run step' -TimeStampBack
Stop-Log
```

To disable the automatic daily run separator:

```powershell
Start-Log -Style Daily -DisableDailySeparator
```

### Timestamp placement

By default timestamps are appended to the end of the message. Use the boolean switch
`-TimeStampFront` to place the timestamp at the start, or use `-TimeStampBack` to explicitly place it at the end.

```powershell
Write-LogInfo -Message 'Processing' -TimeStampFront
```

## Emailing logs

>[!Note] 
>
> `Send-Log` uses .NET `SmtpClient` and may require adjustments for authenticated SMTP servers.

Use `Send-Log` to email a log file. Example:

```powershell
Send-Log -SMTPServer 'smtp.example.com' -LogPath .\log\today.log -EmailFrom 'me@x' -EmailTo 'you@x' -EmailSubject 'Log'
```

## Function Reference

- `Start-Log` — Initialize logging and create the file/folder structure.
- `Write-LogInfo` — Append informational messages.
- `Write-LogWarning` — Append warning messages.
- `Write-LogError` — Append error messages; supports graceful exit.
- `Stop-Log` — Write footer (finish time, elapsed) and optionally exit.
- `Send-Log` — Send a completed log via SMTP.

## Contributing

Suggestions, fixes, and enhancements welcome. For larger changes (structured
logging, JSON output, rotation), see the module `plans.md` roadmap.

## License

See repository LICENSE.
