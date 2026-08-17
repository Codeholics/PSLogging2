# PSLogging2 Implementation Plan

This plan reflects the items still not resolved in `Docs/Review.md` after the recent concurrency and `Stop-Log` exit fixes.

Status legend:

- ✅ complete
- ❌ no longer valid / replaced
- 🚧 working on
- ⏳ pending future step

## Roadmap

### 🚧 Milestone 1: Reliability baseline

- 🚧 Finish the remaining correctness work in `Start-Log`, `Stop-Log`, and the writer functions.
- ⏳ Remove unsafe control-flow patterns such as `Exit 1` inside reusable module code.
- ⏳ Standardize validation and error handling across the module.

### ⏳ Milestone 2: Operational hardening

- ⏳ Improve `Send-Log` reliability, validation, disposal, and large-log handling.
- ⏳ Reduce remaining script-scope and lifecycle risks.
- ⏳ Add tests for the core logging lifecycle and failure paths.

### ⏳ Milestone 3: Documentation and UX cleanup

- ⏳ Bring `README.md`, comment-based help, and `Review.md` into alignment with actual behavior.
- ⏳ Simplify timestamp configuration and other rough edges in the public API.
- ⏳ Make the module easier to adopt safely in automation environments.

### ⏳ Milestone 4: Architecture decisions

- ⏳ Decide whether to keep module-wide script state or move toward explicit log context/state.
- ⏳ Decide whether parallel runspace support is a target feature or out of scope.
- ⏳ Use those decisions to shape any broader refactor.

### ⏳ Milestone 5: Future enhancements

- ⏳ Add structured logging once the plain-text logging surface is stable.
- ⏳ Add configuration-file support after the runtime behavior and API are settled.

## 🚧 Phase 1: Stabilize Core Logging Behavior

### 🚧 1. Harden `Start-Log`

- ✅ Add `[CmdletBinding()]`.
- Throw on header or initialization failure instead of only writing an error and continuing.
- ✅ Fix the outdated inline comment on `Style` so it matches the supported values.
- Decide whether script-scope state is acceptable long term or whether log state should be passed explicitly.
 - ✅ Throw on header or initialization failure instead of only writing an error and continuing.
 - ⏳ Decide whether script-scope state is acceptable long term or whether log state should be passed explicitly.

### ⏳ 2. Harden `Stop-Log`

- ✅ Add `[CmdletBinding()]`.
- Add error handling around footer writes.
- Replace multiple `Add-Content` calls with a single atomic footer write helper.
- Clear script-scope state after completion (`$script:LogStopwatch`, `$script:currentLogPath`).
- Improve elapsed time formatting for runs longer than 59 minutes.
- ✅ Normalize parameter naming to match the rest of the module (`LogPath` instead of `logPath`).
 - ✅ Add error handling around footer writes.
 - ✅ Replace multiple `Add-Content` calls with a single atomic footer write helper.
 - ✅ Clear script-scope state after completion (`$script:LogStopwatch`, `$script:currentLogPath`).
 - ✅ Improve elapsed time formatting for runs longer than 59 minutes.
 - ✅ Normalize parameter naming to match the rest of the module (`LogPath` instead of `logPath`).

### ⏳ 3. Harden log writer functions

Applies to `Write-LogInfo`, `Write-LogWarning`, and `Write-LogError`.

- ✅ Add `[CmdletBinding()]` to all three functions.
- Add `[ValidateNotNullOrEmpty()]` to `Message` parameters.
- ✅ Remove the conflicting dual-switch timestamp model.
	Use either parameter sets or a single parameter such as `-TimestampPosition Front|Back`.
- Remove the pre-write `Test-Path` check and rely on the atomic append helper so existence checks do not race file creation/deletion.
 - ✅ Add `[ValidateNotNullOrEmpty()]` to `Message` parameters.
 - ✅ Remove the conflicting dual-switch timestamp model; use `-TimestampPosition Front|Back|None`.
 - ✅ Remove the pre-write `Test-Path` check and rely on the atomic append helper so existence checks do not race file creation/deletion.

### ⏳ 4. Rework `Write-LogError` exit behavior

- Replace `Exit 1` with a caller-controlled failure pattern.
	Preferred options:
	- `throw`
	- `Write-Error` plus `return`
- Decide whether logging failures in `Write-LogError` should stay warnings or become error-stream output.
- Revisit pipeline support so it is either fully supported or removed.
 - ✅ Replace `Exit 1` with a caller-controlled failure pattern (now uses `Stop-Log` and default exit behavior).
 - ⏳ Decide whether logging failures in `Write-LogError` should stay warnings or become error-stream output.
 - ⏳ Revisit pipeline support so it is either fully supported or removed.

### 🔁 Migration: Removing script-scope state

- The module no longer sets or relies on `$script:currentLogPath` or `$script:LogStopwatch`. All public writers and `Send-Log` accept an explicit `-LogContext` (or `-LogPath`).
- Callers must capture the context returned by `Start-Log -ReturnContext` or create one with `New-LogContext` and pass it to writer functions and `Stop-Log`.

Example (before):

```powershell
# legacy implicit state
Start-Log -Style Simple -LogDir .\log -Title 'Job'
Write-LogInfo -Message 'step'
Stop-Log
```

Example (after):

```powershell
# explicit LogContext
`$ctx = Start-Log -Style Simple -LogDir .\log -Title 'Job' -ReturnContext
Write-LogInfo -Message 'step' -LogContext `$ctx
Stop-Log -LogContext `$ctx
```

Migration steps:

- Search your scripts for `Start-Log`/writers that rely on implicit script state and update to capture `-ReturnContext` and pass `-LogContext`.
- Update automation and tests to use `-LogContext` or explicit `-LogPath`.
- Run the Pester suite and smoke tests to validate behavior.


## ⏳ Phase 2: Harden `Send-Log`

### ⏳ 1. Fix SMTP behavior and validation

- Add `[ValidateNotNullOrEmpty()]` to `LogPath`, `EmailFrom`, `EmailTo`, and `EmailSubject`.
- Set SMTP timeout before calling `.Send()`.
- Dispose the SMTP client reliably.
- Standardize the error-handling strategy instead of mixing `Write-Error` with boolean return values.

### ⏳ 2. Improve message handling

- Decide whether `EmailTo` should remain a single string or become `[string[]]` with a `MailMessage` object.
- Decide how to handle large logs.
	Options:
	- Attach the file instead of embedding it
	- Enforce a size limit
	- Truncate with a notice
- Document or implement a redaction strategy for secrets before emailing logs.

### ⏳ 3. Plan for auth modernization

- Document that `SmtpClient` is legacy and define the upgrade path.
- Evaluate whether modern auth support belongs in this module or a separate mail transport layer.

## ⏳ Phase 3: Align Documentation And Tests

### ⏳ 1. Fix documentation drift

- Update `README.md` to match current timestamp behavior.
	Right now the docs imply timestamps are appended by default, but the code only adds them when a timestamp switch is provided.
- Review all function help text for parameters and examples so they match current behavior.
- Continue pruning stale findings from `Docs/Review.md` as fixes land.
 - ✅ Update `README.md` to match current timestamp behavior and explicit `LogContext` usage.

### ⏳ 2. Expand Validation Coverage

#### ✅ Existing Coverage

- ✅ Stop-Log footer writing
- ✅ Write-LogError -ExitGracefully behavior
- ✅ Timestamp formatting and validation
- ✅ LogContext workflow validation
- ✅ Send-Log success-path validation
- ✅ Concurrent multi-process writes

#### ⏳ Failure Path Testing

- ⏳ Add tests for retry exhaustion in `Append-LogAtomic`.
- ⏳ Add tests for invalid or malformed `LogContext` objects.
- ⏳ Add tests for underlying append failures in writer functions.
- ⏳ Add tests for `Send-Log` SMTP exceptions.
- ⏳ Add tests for log directory creation failures.

#### ⏳ Concurrency Integrity Validation

Extend the existing concurrency suite to validate:

- ⏳ Exact expected entry count.
- ⏳ Duplicate entry detection.
- ⏳ Corrupted or interleaved entry detection.
- ⏳ Header integrity validation.
- ⏳ Footer integrity validation.

#### ⏳ Daily Initialization Race Testing

Add validation for concurrent startup scenarios:

- ⏳ Multiple PowerShell processes simultaneously running:

```powershell
Start-Log -Style Daily
```

against a non-existent daily log.

Validate:

- Only one header is created.
- No duplicate initialization data exists.
- No corruption occurs.
- No initialization failures occur.

Recent verification:

- ✅ `Tests/Pester/Timestamp.Tests.ps1` now covers `-TimestampPosition Front|Back|None` formatting and invalid value rejection.
- ✅ Full `Tests/Pester` suite passes after the LogContext, Send-Log, concurrency, and timestamp test updates.

## Additional Atomic Logging Validation

The existing concurrency test suite validates multi-process and multi-job logging behavior.

Additional validation targets:

### ⏳ Concurrency Scale Testing

- ⏳ 1,000+ simultaneous writes
- ⏳ Multiple PowerShell jobs
- ⏳ Multiple PowerShell processes
- ⏳ Multiple runspaces
- ⏳ Mixed workload scenarios

### ⏳ Integrity Validation

Validate:

- ⏳ No duplicate entries
- ⏳ No missing entries
- ⏳ No malformed entries
- ⏳ No interleaved/corrupted log lines
- ⏳ Exact expected entry counts
- ⏳ Correct header creation behavior
- ⏳ Correct footer creation behavior

### ⏳ Environment Validation

Validate behavior with:

- ⏳ Network shares
- ⏳ High I/O contention
- ⏳ Long-running daily logs

## ⏳ Deferred Architecture Work

- Evaluate whether module-wide script variables should be replaced with explicit state passed between functions.
- Evaluate whether parallel runspace support is a goal for this module or out of scope.

## ⏳ Internal Architecture Improvements

### ⏳ Centralize LogPath Resolution

The following functions currently contain duplicate LogContext-to-LogPath resolution logic:

- Write-LogInfo
- Write-LogWarning
- Write-LogError
- Send-Log

Evaluate creating a private helper:

```powershell
Resolve-LogPath
```

Benefits:

- Reduces duplication
- Simplifies maintenance
- Provides consistent path resolution behavior
- Makes future enhancements easier

### ⏳ Standardize Exception Message Formatting

Several functions currently generate exception messages independently.

Evaluate creating a private helper:

```powershell
New-LogExceptionMessage
```

Benefits:

- Consistent diagnostics
- Easier troubleshooting
- Better GitHub issue reporting
- Clearer production logging failures

### ⏳ Establish Private Helper Structure

Consider organizing reusable internal functionality within a dedicated private folder structure.

Example:

```text
Functions\
    Private\
        Resolve-LogPath.ps1
        New-LogExceptionMessage.ps1
```

Benefits:

- Cleaner architecture
- Better separation of concerns
- Easier long-term maintenance
- Simpler contributor onboarding

## ⏳ Future Enhancements

- ⏳ **Structured Logging:** Add a `-Json` switch. Instead of plain text, output logs as JSON objects to allow for easier ingestion by tools like Splunk, ELK Stack, or Azure Monitor.
- ⏳ **Configuration Files:** Implement `.json` or `.xml` configuration files so users don't have to pass long parameter strings every time they call the function.
- ✅ **Pester Test(s):** A great method to unit test the function to help identity bugs and resolve them.
- ⏳ **Teams Webhook:** Get notified via Microsoft teams when an error is logged or automation completed
- ⏳ **ServiceNow Incident:** Create a ServiceNow Incident if an error is logged
- ⏳ **Email through Graph:** Send-Logs via Email with Graph (as an option) because Graph is becoming more popular for IT teams to send automated emails in a Microsoft environment.
- ⏳ **Jenkins notifications:**: (This feature was recommended, but I am not sure of the exact use case)
