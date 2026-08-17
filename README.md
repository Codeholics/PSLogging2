# PSLogging2

![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-334155?style=flat-square&logo=powershell&logoColor=white)
![Module](https://img.shields.io/badge/module-logging-475569?style=flat-square)
![Status](https://img.shields.io/badge/status-active-0f766e?style=flat-square)
![Concurrency](https://img.shields.io/badge/concurrency-atomic%20appends-9a3412?style=flat-square)
![Automation](https://img.shields.io/badge/use%20case-automation-1d4ed8?style=flat-square)

[Quick Start](#quick-start) • [Log Styles](#log-styles) • [Functions](#functions) • [Concurrency](#concurrency) • [Development](#development)

Lightweight PowerShell logging for scripts, scheduled tasks, and automation jobs.

PSLogging2 provides file-based logging with simple writer functions, multiple log file layouts, optional timestamps, and SMTP delivery for completed logs. The module is designed for straightforward use in PowerShell 5.1 style environments while still being usable in newer shells.

## Highlights

- Three log file layouts: `Simple`, `Standard`, and `Daily`
- Dedicated helpers for info, warning, and error messages
- Optional timestamp placement controlled by `-TimestampPosition <Front|Back|None>`
- Daily log reuse with automatic run separators
- Atomic append logic for safer concurrent writes
- Optional SMTP delivery with `Send-Log`

## Repository Layout

```text
PSLogging2/
|- Functions/     # Module functions
|- Docs/          # Review notes and planning docs
|- Tests/         # Validation and smoke-test scripts
|- PSLogging2.psm1
|- PSLogging2.psd1
`- README.md
```

## Installation

### Import from the repo

```powershell
Import-Module .\PSLogging2.psm1 -Force
```

### Install as a local module

Copy the `PSLogging2` folder into one of your PowerShell module paths, then import it normally:

```powershell
Import-Module PSLogging2
```

## Quick Start

```powershell
Import-Module .\PSLogging2.psm1 -Force

Start-Log -Style Simple -LogDir .\log -Title 'Inventory Script' -Version '1.0' -ToScreen
Write-LogInfo -Message 'Starting run'
Write-LogWarning -Message 'Using fallback configuration' -TimestampPosition Front
Write-LogInfo -Message 'Completed step 1' -TimestampPosition Back
Stop-Log -ToScreen
```

## Log Styles

### `Simple`

Creates one log file per run.

Example output path:

```text
log\2026-08-15_214530.log
```

### `Standard`

Creates nested year and month folders, then writes a timestamped file for each run.

Example output path:

```text
log\2026\2026-08\2026-08-15_214530.log
```

Use this when you want a clean archive layout for long-running or recurring automation.

### `Daily`

Writes all runs for the same day into a shared daily log.

Example output path:

```text
log\2026\2026-08\2026-08-15.log
```

When the file already exists, the module appends a run separator unless `-DisableDailySeparator` is used.

## Common Examples

### Standard logging

```powershell
Start-Log -Style Standard -LogDir .\log -Title 'Nightly Job' -Version '2.3'
Write-LogInfo -Message 'Job started'
Write-LogInfo -Message 'Import complete' -TimestampPosition Back
Stop-Log
```

### Daily logging

```powershell
Start-Log -Style Daily -LogDir .\log -Title 'Daily Sync'
Write-LogInfo -Message 'Sync started' -TimestampPosition Front
Write-LogWarning -Message 'Remote system responded slowly'
Stop-Log
```

### Error logging

```powershell
Start-Log -Style Simple -LogDir .\log -Title 'Deployment'
Write-LogError -Message 'Deployment failed' -TimestampPosition Back -ToScreen
Stop-Log
```

## Timestamp Behavior

Timestamps are optional and controlled by the `-TimestampPosition` parameter.

- `-TimestampPosition None` (default): message is written as-is
- `-TimestampPosition Front`: timestamp is prepended
- `-TimestampPosition Back`: timestamp is appended

Example:

```powershell
Write-LogInfo -Message 'Processing item' -TimestampPosition Front
Write-LogWarning -Message 'Retrying request' -TimestampPosition Back
```

## Functions

| Function | Purpose |
| --- | --- |
| `Start-Log` | Initializes the log path and writes the run header |
| `Write-LogInfo` | Appends informational messages |
| `Write-LogWarning` | Appends warning messages |
| `Write-LogError` | Appends error messages and can optionally stop execution |
| `Stop-Log` | Writes footer information and exits by default (use `-NoExit` to prevent exiting) |
| `Send-Log` | Emails a completed log file through SMTP |

## Concurrency

PSLogging2 now uses atomic append logic for log writes.

- Safer concurrent writes for `Simple`, `Standard`, and `Daily`
- Daily mode can be shared across multiple runs without the earlier append race
- Header and separator creation are also protected through the same log I/O helper approach

### Concurrency test

The repo includes a basic concurrency test:

```powershell
Set-Location .\Tests
.\Test-ConcurrentDaily.ps1 -Jobs 8 -LinesPerJob 250
```

## Sending Logs By Email

`Send-Log` sends the full log body through .NET `SmtpClient`.

```powershell
Send-Log `
	-SMTPServer 'smtp.example.com' `
	-LogPath .\log\2026\2026-08\2026-08-15.log `
	-EmailFrom 'me@example.com' `
	-EmailTo 'team@example.com' `
	-EmailSubject 'Nightly Job Log'
```

Notes:

- This currently uses legacy `SmtpClient`
- The full log is read into memory before sending
- Modern auth and large-log handling are future hardening items

## Current Limitations

- Writer functions use script-scoped module state (consider moving to explicit context)
- `Send-Log` is functional but not fully enterprise-hardened yet (modern auth, large-log handling)
- Pipeline support for `Write-LogError` is not fully implemented and may be removed or revised

Notes:
- `Stop-Log` exits by default after writing the footer; pass `-NoExit` to prevent exiting.
- Timestamp switches were replaced with `-TimestampPosition` and writer functions now validate `Message` input.

## Development

### Run the concurrency test

```powershell
Set-Location .\Tests
.\Test-ConcurrentDaily.ps1
```

### Review planned work

- Implementation roadmap: `Docs/plans.md`
- Review notes: `Docs/Review.md`

## Contributing

Issues, fixes, and improvements are welcome. If you are planning a broader change, check `Docs/plans.md` first so the work lines up with the current roadmap.

## License

This project is licensed under the terms in `LICENSE`.
