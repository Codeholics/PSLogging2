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

### ⏳ 2. Harden `Stop-Log`

- Add `[CmdletBinding()]`.
- Add error handling around footer writes.
- Replace multiple `Add-Content` calls with a single atomic footer write helper.
- Clear script-scope state after completion (`$script:LogStopwatch`, `$script:currentLogPath`).
- Improve elapsed time formatting for runs longer than 59 minutes.
- Normalize parameter naming to match the rest of the module (`LogPath` instead of `logPath`).

### ⏳ 3. Harden log writer functions

Applies to `Write-LogInfo`, `Write-LogWarning`, and `Write-LogError`.

- Add `[CmdletBinding()]` to all three functions.
- Add `[ValidateNotNullOrEmpty()]` to `Message` parameters.
- Remove the conflicting dual-switch timestamp model.
	Use either parameter sets or a single parameter such as `-TimestampPosition Front|Back`.
- Remove the pre-write `Test-Path` check and rely on the atomic append helper so existence checks do not race file creation/deletion.

### ⏳ 4. Rework `Write-LogError` exit behavior

- Replace `Exit 1` with a caller-controlled failure pattern.
	Preferred options:
	- `throw`
	- `Write-Error` plus `return`
- Decide whether logging failures in `Write-LogError` should stay warnings or become error-stream output.
- Revisit pipeline support so it is either fully supported or removed.

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

### ⏳ 2. Add focused validation coverage

- Add a smoke test for `Stop-Log` footer writing.
- Add a smoke test for `Write-LogError -ExitGracefully` once its behavior is redesigned.
- Add tests for timestamp option validation.
- Add a test for `Send-Log` validation behavior.

## ⏳ Deferred Architecture Work

- Evaluate whether module-wide script variables should be replaced with explicit state passed between functions.
- Evaluate whether parallel runspace support is a goal for this module or out of scope.

## ⏳ Future Enhancements

- ⏳ **Structured Logging:** Add a `-Json` switch. Instead of plain text, output logs as JSON objects to allow for easier ingestion by tools like Splunk, ELK Stack, or Azure Monitor.
- ⏳ **Configuration Files:** Implement `.json` or `.xml` configuration files so users don't have to pass long parameter strings every time they call the function.
- ⏳ **Pester Test(s):** A great method to unit test the function to help identity bugs and resolve them.
