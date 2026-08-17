# Log Context Design: script-state vs explicit context

This document summarizes options for the module's log state model, trade-offs, backward compatibility, API sketches, tests, and a recommended path.

Goals
- Make logging safe and testable across parallel runs/runspaces.
- Preserve existing behavior for current consumers where practical.
- Provide a clear migration path and small, incremental implementation steps.

Options

1) Keep script-scoped state (current behavior)
- Mechanism: `Start-Log` writes `$script:currentLogPath` and `$script:LogStopwatch`; writers use these when `-LogPath`/`-LogContext` not supplied.
- Pros: Minimal change, simplest for existing scripts, lowest short-term risk.
- Cons: Hard to use safely in parallel runspaces or where multiple logs are open in the same process; harder to unit test.

2) Explicit `LogContext` (recommended long-term)
- Mechanism: `Start-Log` returns a `LogContext` object/hashtable (or `New-LogContext -LogPath`) and writers accept `-LogContext` or `-LogPath`.
- Pros: Safe for parallel runs, explicit lifecycle, easy to unit-test and to pass between functions/runspaces.
- Cons: Requires changes to callers; migration needed.

3) Hybrid (recommended immediate approach)
- Mechanism: Add an optional `-LogContext` parameter to all writers and `Start-Log` can *optionally* return a context (or `New-LogContext` helper). Keep `$script:` state only as a fallback for backwards compatibility.
- Behavior: Writers use `-LogContext` if provided, else use explicit `-LogPath` parameter if given, else fall back to `$script:currentLogPath`.
- Migration: Document `-LogContext` and deprecate relying on `$script:` over time (e.g., 2-3 releases). Provide a linter/test script to find uses.

API sketches

- New-LogContext example:
  `New-LogContext -LogPath 'C:\logs\run.log' -Title 'job'`
  returns a hashtable/object `{ LogPath = '...'; Started = <datetime>; Stopwatch = <stopwatch> }`

- Start-Log returns context (optional):
  `$ctx = Start-Log -LogPath 'C:\logs\run.log' -ReturnContext`

- Writer usage:
  `Write-LogInfo -Message 'hello' -LogContext $ctx`
  or
  `Write-LogInfo -Message 'hello' -LogPath 'C:\logs\run.log'`

Backward compatibility
- Keep `$script:currentLogPath` populated by `Start-Log` and leave writer overloads unchanged so existing scripts continue to work.
- Add `-LogContext`/`-LogPath` parameters and prefer them in new code and examples.

Tests and migration steps
- Add unit/integration tests for:
  - Writers when passed `-LogContext` (concurrent writes using separate contexts).
  - Writers when only `$script:` is set (existing behavior).
- Provide example migration snippet in `Docs/` and update README examples.

Recommendation and next steps
1. Implement the hybrid model: add `-LogContext` parameter to `Write-Log*` and `Send-Log` and support a `-ReturnContext` switch on `Start-Log`.
2. Create `New-LogContext` helper for advanced scenarios and runspace use.
3. Add tests for context-based writes and update README/examples.

I can prototype the hybrid API by updating `Start-Log` to return a small context object and adding `-LogContext` to `Write-LogInfo` and one test. Proceed to prototype?