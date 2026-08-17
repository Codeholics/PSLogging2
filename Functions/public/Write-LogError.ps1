<#
.SYNOPSIS
    Append an error message to the current log file.

.DESCRIPTION
    Writes an error-level message to the log initialized by `Start-Log`.
    Optionally adds a timestamp and can exit the calling script gracefully
    after writing the error by running `Stop-Log`.

.PARAMETER Message
    The error message text to append.

.PARAMETER TimestampPosition
    Controls timestamp placement. Accepts `Front`, `Back`, or `None` (default).

.PARAMETER TimeStampFront
    (Deprecated) Old switch. Use `-TimestampPosition Front` instead.

.PARAMETER TimeStampBack
    (Deprecated) Old switch. Use `-TimestampPosition Back` instead.

.PARAMETER ExitGracefully
    If specified, `Stop-Log` is executed (writes footer) and the calling
    process will exit by default; pass `-NoExit` to `Stop-Log` to suppress
    exiting.

.PARAMETER ToScreen
    When specified, also write the formatted error to the host.

.EXAMPLE
    Write-LogError -Message 'Fatal failure' -TimestampPosition Back -ExitGracefully
#>
function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Message,
        [ValidateSet('Front','Back','None')][string]$TimestampPosition = 'None',
        [switch]$ExitGracefully,
        [switch]$ToScreen
    )

    $targetPath = $script:currentLogPath

    if ($TimestampPosition -ne 'None') {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($TimestampPosition -eq 'Front') { $line = "ERROR: $ts $Message" } else { $line = "ERROR: $Message $ts" }
    } else {
        $line = "ERROR: $Message"
    }

    if ($ToScreen) { Write-Host $line -ForegroundColor Red }

    if ($null -ne $targetPath) {
        try {
            Append-LogAtomic -Path $targetPath -Value $line -MaxRetries 8 -RetryDelayMs 200 | Out-Null
        } catch {
            Write-Warning "Failed to append error to log: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Cannot write error to log. Path is null."
    }

    if ($ExitGracefully) {
        Stop-Log -LogPath $targetPath
    }
}