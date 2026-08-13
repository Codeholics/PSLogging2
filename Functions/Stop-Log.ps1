<#
.SYNOPSIS
    Finish logging and write closing information to the log file.

.DESCRIPTION
    Writes footer information (finish time and elapsed time) to the current
    log file and optionally exits the calling script.

.PARAMETER logPath
    Optional explicit path to a log file. Defaults to the current log file
    initialized by `Start-Log`.

.PARAMETER Exit
    When specified, `Stop-Log` writes footer data and then exits the calling
    process.

.PARAMETER NoExit
    Legacy compatibility switch. Ignored unless used together with `-Exit`, in
    which case it suppresses exiting.

.PARAMETER ToScreen
    When specified, writes a short completion message to the host.

.EXAMPLE
    Stop-Log -ToScreen
#>
function Stop-Log {
    param(
        [string]$logPath = $script:currentLogPath,
        [switch]$Exit,
        [switch]$NoExit,
        [switch]$ToScreen
    )

    if (-not (Test-Path -Path $logPath)) { return }

    if ($null -ne $script:LogStopwatch) {
        $script:LogStopwatch.Stop()
        $elapsed = $script:LogStopwatch.Elapsed
    } else {
        $elapsed = [Timespan]::Zero
    }

    $endTime = Get-Date

    Add-Content -Path $logPath -Value "" -Encoding UTF8
    Add-Content -Path $logPath -Value "***************************************************************************************************" -Encoding UTF8
    Add-Content -Path $logPath -Value "Finished at: $endTime" -Encoding UTF8
    Add-Content -Path $logPath -Value "Total Execution Time: $($elapsed.Minutes)m $($elapsed.Seconds)s" -Encoding UTF8
    Add-Content -Path $logPath -Value "***************************************************************************************************" -Encoding UTF8

    if ($ToScreen) {
        Write-Host "Log finished: $logPath" -ForegroundColor Cyan
    }

    #Exit calling script if NoExit has not been specified or is set to False
    If(-not($NoExit) -or ($NoExit -eq $False)){
      Exit
    }
}