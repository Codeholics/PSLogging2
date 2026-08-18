<#
.SYNOPSIS
    Finish logging and write closing information to the log file.

.DESCRIPTION
    Writes footer information (finish time and elapsed time) to the current
    log file and optionally exits the calling script.

.PARAMETER LogPath
    Optional explicit path to a log file. Defaults to the current log file
    initialized by `Start-Log`.

:PARAMETER Exit
    When specified, `Stop-Log` will exit the calling process after writing
    footer data. By default `Stop-Log` will NOT exit the calling process; callers
    should decide whether to exit after `Stop-Log` returns.
.EXAMPLE
    Stop-Log -ToScreen

    This example writes the footer information and then exits (default).
#>
function Stop-Log {
    [CmdletBinding()]
    param(
        [object]$LogContext,
        [string]$LogPath,
        [switch]$ToScreen,
        [switch]$Exit
    )

    # Determine effective LogPath
    if ($null -ne $LogContext -and ($LogContext.PSObject.Properties.Name -contains 'LogPath')) {
        $LogPath = $LogContext.LogPath
    }

    if ($null -eq $LogPath) { return }

    # Determine elapsed using provided LogContext.Stopwatch if available
    if ($null -ne $LogContext -and ($LogContext.PSObject.Properties.Name -contains 'Stopwatch')) {
        try {
            $LogContext.Stopwatch.Stop()
            $elapsed = $LogContext.Stopwatch.Elapsed
        } catch {
            $elapsed = [Timespan]::Zero
        }
    } else {
        $elapsed = [Timespan]::Zero
    }

    $endTime = Get-Date

    # Build footer block and write atomically using Append-LogAtomic
    $elapsedString = $elapsed.ToString('c')
    $footerLines = @()
    $footerLines += ''
    $footerLines += '***************************************************************************************************'
    $footerLines += "Finished at: $endTime"
    $footerLines += "Total Execution Time: $elapsedString"
    $footerLines += '***************************************************************************************************'

    $footer = $footerLines -join "`r`n"

    try {
        Append-LogAtomic -Path $LogPath -Value $footer | Out-Null
    } catch {
        Write-Error "Failed to write footer to log '$LogPath': $($_.Exception.Message)"
    }

    if ($ToScreen) {
        Write-Host "Log finished: $LogPath" -ForegroundColor Cyan
    }

    if ($Exit) {
        Exit 0
    }

    # No script-scoped state to clear (module uses explicit LogContext)

    # Do not exit the caller from module code; return status and let the caller decide.
    return $true
}