<#
.SYNOPSIS
    Finish logging and write closing information to the log file.

.DESCRIPTION
    Writes footer information (finish time and elapsed time) to the current
    log file and optionally exits the calling script.

.PARAMETER LogPath
    Optional explicit path to a log file. Defaults to the current log file
    initialized by `Start-Log`.

.PARAMETER NoExit
    When specified, `Stop-Log` will NOT exit the calling process after writing
    footer data. By default `Stop-Log` will exit the process unless `-NoExit`
    is provided.
.EXAMPLE
    Stop-Log -ToScreen

    This example writes the footer information and then exits (default).
#>
function Stop-Log {
    [CmdletBinding()]
    param(
        [string]$LogPath = $script:currentLogPath,
        [switch]$NoExit,
        [switch]$ToScreen
    )

    if ($null -eq $LogPath) { return }

    if ($null -ne $script:LogStopwatch) {
        $script:LogStopwatch.Stop()
        $elapsed = $script:LogStopwatch.Elapsed
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
        Append-LogAtomic -Path $LogPath -Value $footer -MaxRetries 8 -RetryDelayMs 200 | Out-Null
    } catch {
        Write-Error "Failed to write footer to log '$LogPath': $($_.Exception.Message)"
    }

    if ($ToScreen) {
        Write-Host "Log finished: $LogPath" -ForegroundColor Cyan
    }

    # Clear script-scope state
    if ($null -ne $script:LogStopwatch) { Remove-Variable -Scope Script -Name LogStopwatch -ErrorAction SilentlyContinue }
    if ($null -ne $script:currentLogPath) { Remove-Variable -Scope Script -Name currentLogPath -ErrorAction SilentlyContinue }

    # By default exit unless -NoExit was supplied
    if (-not $NoExit) {
        Exit
    }
}