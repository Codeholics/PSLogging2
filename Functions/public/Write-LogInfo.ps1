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
        [switch]$ToScreen,
        [Parameter(Mandatory=$false)]
        [object]
        $LogContext,
        [Parameter(Mandatory=$false)]
        [string]
        $LogPath
    )

    # Determine target path from LogContext or explicit LogPath
    if ($null -ne $LogContext) {
        if ($LogContext -is [System.Collections.IDictionary] -and $LogContext.ContainsKey('LogPath')) {
            $targetPath = $LogContext['LogPath']
        } elseif ($null -ne $LogContext -and ($LogContext.PSObject.Properties.Name -contains 'LogPath')) {
            $targetPath = $LogContext.LogPath
        } else {
            throw "Write-LogInfo requires a single LogContext object with a LogPath property."
        }
    } elseif ($PSBoundParameters.ContainsKey('LogPath') -and $LogPath) {
        $targetPath = $LogPath
    } else {
        throw "Write-LogInfo requires -LogContext or -LogPath to be provided."
    }

    # Determine effective timestamp position.
    if ($TimestampPosition -ne 'None') {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($TimestampPosition -eq 'Front') { $formatted = "$ts $Message" } else { $formatted = "$Message $ts" }
    } else {
        $formatted = $Message
    }

    if ($ToScreen) { Write-Host $formatted -ForegroundColor Cyan }

    try {
        Append-LogAtomic -Path $targetPath -Value "- $($formatted)" | Out-Null
    } catch {
        throw "Failed to append to log: $($_.Exception.Message)"
    }
}