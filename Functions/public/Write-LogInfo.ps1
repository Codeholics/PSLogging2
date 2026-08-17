<#
.SYNOPSIS
    Append an informational line to the current log file.

.DESCRIPTION
    Writes an informational message to the log initialized by `Start-Log`.
    Supports optional timestamping and writing to host output.

.PARAMETER Message
    The message text to append to the log.

.PARAMETER TimestampPosition
    Controls timestamp placement. Accepts `Front`, `Back`, or `None` (default).

.PARAMETER TimeStampFront
    (Deprecated) Old switch. Use `-TimestampPosition Front` instead.

.PARAMETER TimeStampBack
    (Deprecated) Old switch. Use `-TimestampPosition Back` instead.

.PARAMETER ToScreen
    When specified, also write the formatted message to the host.

.EXAMPLE
    Write-LogInfo -Message 'Processing item' -TimestampPosition Front
#>
function Write-LogInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [ValidateSet('Front','Back','None')]
        [string]$TimestampPosition = 'None',
        [switch]$ToScreen
    )

    # Use the script scope variable that was established in Start-Log.ps1
    $targetPath = $script:currentLogPath

    # Determine effective timestamp position.
    if ($TimestampPosition -ne 'None') {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($TimestampPosition -eq 'Front') { $formatted = "$ts $Message" } else { $formatted = "$Message $ts" }
    } else {
        $formatted = $Message
    }

    if ($ToScreen) { Write-Host $formatted -ForegroundColor Cyan }

    if ($null -ne $targetPath) {
        try {
            Append-LogAtomic -Path $targetPath -Value "- $($formatted)" -MaxRetries 8 -RetryDelayMs 200 | Out-Null
        } catch {
            Write-Warning "Failed to append to log: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Cannot write to log. Path is null."
    }
}