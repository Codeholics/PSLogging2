# PSLogging2 Implementation Plan

Status legend:

- ✅ complete
- ❌ no longer valid / replaced
- 🚧 working on
- ⏳ pending future step

## Roadmap

### ✅ Milestone 1: Reliability baseline

- ✅ Finish the remaining correctness work in `Start-Log`, `Stop-Log`, and the writer functions.
- ✅ Remove unsafe control-flow patterns such as `Exit 1` inside reusable module code.
- ✅ Standardize validation and error handling across the module.

### ✅ Milestone 2: Operational hardening

- ✅ Improve `Send-Log` reliability, validation, disposal, and large-log handling.
- ✅ Reduce remaining lifecycle and error-handling risks.
- ✅ Add tests for the core logging lifecycle and failure paths.

### ⏳ Milestone 3: Documentation and UX cleanup

- ✅ Bring `README.md` and `Review.md` into alignment with actual behavior.
- ✅ Simplify timestamp configuration and other rough edges in the public API.
- ✅ Add usage documentation for the current `Send-Log` options in [Send-Log.md](Send-Log.md).

### ⏳ Milestone 4: Architecture decisions

- ✅ Keep explicit `LogContext`/`LogPath` state as the long-term design; do not reintroduce module-wide script state.
- ⏳ Decide whether parallel run space support is a target feature or out of scope.
- ⏳ Use those decisions to shape any broader refactor.

### ⏳ Milestone 5: Future enhancements

- ⏳ Add structured logging once the plain-text logging surface is stable.
- ⏳ Add configuration-file support after the runtime behavior and API are settled.

## ✅ Phase 1: Stabilize Core Logging Behavior

### ✅ 1. Harden `Start-Log`

- ✅ Add `[CmdletBinding()]`.
- ✅ Fix the outdated inline comment on `Style` so it matches the supported values.
- ✅ Use explicit `LogContext`/`LogPath` state long term; treat script-scope state as retired.
- ✅ Throw on header or initialization failure instead of only writing an error and continuing.

### ✅ 2. Harden `Stop-Log`

- ✅ Add `[CmdletBinding()]`.
- ✅ Normalize parameter naming to match the rest of the module (`LogPath` instead of `logPath`).
 - ✅ Add error handling around footer writes.
 - ✅ Replace multiple `Add-Content` calls with a single atomic footer write helper.
 - ✅ Clear script-scope state after completion (`$script:LogStopwatch`, `$script:currentLogPath`).
 - ✅ Improve elapsed time formatting for runs longer than 59 minutes.
 - ✅ Normalize parameter naming to match the rest of the module (`LogPath` instead of `logPath`).

### ✅ 3. Harden log writer functions

Applies to `Write-LogInfo`, `Write-LogWarning`, and `Write-LogError`.

- ✅ Add `[CmdletBinding()]` to all three functions.
- ✅ Remove the conflicting dual-switch timestamp model. Use either parameter sets or a single parameter such as `-TimestampPosition Front|Back`.
 - ✅ Add `[ValidateNotNullOrEmpty()]` to `Message` parameters.
 - ✅ Remove the pre-write `Test-Path` check and rely on the atomic append helper so existence checks do not race file creation/deletion.

### ✅ 4. Rework `Write-LogError` exit behavior

- ✅ Replace `Exit 1` with a caller-controlled failure pattern (now uses `Stop-Log` with explicit `-Exit` behavior).
- ✅ Treat logging failures in `Write-LogError` as error-stream / terminating failures, not warnings, so automation cannot silently miss a failed error log write.
- ✅ Removed the partial pipeline-oriented behavior; `Write-LogError`, writers, and `Send-Log` now require a single `-LogContext` or explicit `-LogPath`. Full pipeline support may be designed later as a dedicated feature.

## ✅ Phase 2: Harden `Send-Log`

### ✅ 1. SMTP behavior and validation

- ✅ Add `[ValidateNotNullOrEmpty()]` to `EmailFrom`, `EmailTo`, and `EmailSubject`.
- ✅ Validate `LogPath` or `LogContext` through `Resolve-LogPath`.
- ✅ Set SMTP timeout before calling `.Send()`.
- ✅ Dispose the SMTP client reliably.
- ✅ Return `$false` and write an error record by default; allow callers to opt into terminating behavior with `-ThrowOnFailure`.

### ✅ 2. Improve message handling

- ✅ Accept comma-separated recipient strings and recipient arrays.
- ✅ Inline logs up to `-MaxInlineSizeMB`; attach larger logs.
- ✅ Support regex-based redaction with `-RedactRegex` and `-RedactionMask`; use a sanitized temporary copy by default and require `-RedactInPlace` to modify the source log.

### ✅ 3. Plan for auth modernization

- ✅ Document that `SmtpClient` is legacy and define the upgrade path in [SendLog-Auth-Modernization.md](SendLog-Auth-Modernization.md).
- ✅ Decide that secure SMTP configuration is the first implementation phase and Microsoft Graph is the only planned built-in modern transport.
- ⏳ Implement the approved Phase 1 secure SMTP configuration and Phase 2 Graph transport.

## ⏳ Phase 3: Align Documentation And Tests

### ⏳ 1. Fix documentation drift

- ✅ Update `README.md` to match current timestamp behavior.
- 🚧 Update remaining function comment-based help, beginning with `Send-Log`, so all implemented parameters and examples match current behavior.
- ✅ Update `README.md` to match explicit `LogContext` usage.
- ✅ Document `Send-Log` delivery, attachment, redaction, and failure-handling options in [Send-Log.md](Send-Log.md).

### ⏳ 2. Expand Validation Coverage

#### ✅ Existing Coverage

- ✅ `Stop-Log` footer writing
- ✅ `Write-LogError -ExitGracefully` behavior
- ✅ Timestamp formatting and validation
- ✅ LogContext workflow validation
- ✅ `Send-Log` success-path validation
- ✅ Concurrent multi-process writes


#### ✅ Failure Path Testing

- ✅ Add retry-exhaustion coverage for `Append-LogAtomic`.
- ✅ Add invalid or malformed `LogContext` coverage.
- ✅ Add underlying append-failure coverage for writer functions.
- ✅ Add `Send-Log` SMTP-exception coverage.
- ✅ Add tests for log directory creation failures.

#### ✅ Concurrency Integrity Validation

Extend the existing concurrency suite to validate:

- ✅ Exact expected entry count.
- ✅ Duplicate entry detection.
- ✅ Corrupted or interleaved entry detection.
- ✅ Header presence validation.
- ✅ Footer integrity validation.

#### ✅ Daily Initialization Race Testing

The existing concurrency test already starts multiple processes against a non-existent daily log. Extend it with explicit initialization assertions:

- ✅ Multiple PowerShell processes simultaneously running:

```powershell
Start-Log -Style Daily
```

against a non-existent daily log.

Validate:

- ✅ Only one header initialization block is created.
- ✅ No duplicate initialization data exists.
- ✅ No malformed run entries are written.
- ✅ No initialization failures occur (worker exit codes are checked).

Current verification: full `Tests/Pester` suite passes (19 passed, 0 failed).

## Additional Atomic Logging Validation

### ⏳ Concurrency Scale Testing

- ✅ 1,000+ writes (verified with 10 PowerShell processes writing 200 lines each).
- ✅ 5,000-write high-I/O run (verified with 10 PowerShell processes writing 500 lines each).
- ⏳ Multiple PowerShell jobs
- ✅ Multiple PowerShell processes
- ⏳ Multiple runspaces
- ⏳ Mixed workload scenarios

### ✅ Integrity Validation

- ✅ No duplicate entries
- ✅ No missing entries
- ✅ No malformed entries
- ✅ No interleaved/corrupted log lines
- ✅ Exact expected entry counts
- ✅ Header presence
- ✅ Correct footer creation behavior

### ⏳ Environment Validation

Validate behavior with:

- 🚧 Network shares (opt-in Pester test is available through `PSLOG_TEST_SHARE`; requires an accessible UNC share).
- ✅ High I/O contention (5,000 writes verified locally with `Tests/Stress/HighLoadStress.ps1`).
- ⏳ Long-running daily logs

## ⏳ Deferred Architecture Work

- Explicit state passed between functions is the chosen direction; do not reintroduce module-wide script variables.
- Evaluate whether parallel runspace support is a goal for this module or out of scope.

## ✅ Internal Architecture Improvements

### ✅ Centralize LogPath Resolution

The following functions currently contain duplicate LogContext-to-LogPath resolution logic:

- `Write-LogInfo`
- `Write-LogWarning`
- `Write-LogError`
- `Send-Log`

Implemented private helper:

```powershell
Resolve-LogPath
```

### ✅ Standardize Exception Message Formatting

Several functions currently generate exception messages independently.

Implemented private helper:

```powershell
New-LogExceptionMessage
```

### ✅ Establish Private Helper Structure

Reusable internal functionality is organized in the private folder.

Example:

```text
Functions\
    Private\
        Resolve-LogPath.ps1
        New-LogExceptionMessage.ps1
```

## ⏳ Future Enhancements

- ⏳ **Structured Logging:** Add a `-Json` switch. Instead of plain text, output logs as JSON objects to allow for easier ingestion by tools like Splunk, ELK Stack, or Azure Monitor.
- ⏳ **Configuration Files:** Implement `.json` or `.xml` configuration files, so users don't have to pass long parameter strings every time they call the function.
- ✅ **Pester Test(s):** A great method to unit test the function to help identify bugs and resolve them.
- ⏳ **Teams Webhook:** Get notified via Microsoft Teams when an error is logged or automation completed
- ⏳ **ServiceNow Incident:** Create a ServiceNow Incident if an error is logged
- ⏳ **Email through Graph:** `Send-Logs` via Email with Graph (as an option) because Graph is becoming more popular for IT teams to send automated emails in a Microsoft environment.
- ⏳ **Jenkins notifications:**: (This feature was recommended, but I am not sure of the exact use case)
