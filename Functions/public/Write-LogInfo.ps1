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
        # If an array/container was passed (e.g. previous pipeline outputs), pick the element that contains LogPath
        if ($PSBoundParameters.ContainsKey('LogContext') -and $LogContext -is [System.Array]) {
            $found = $null
            foreach ($item in $LogContext) {
                try {
                    if ($item -is [System.Collections.IDictionary] -and $item.ContainsKey('LogPath')) { $found = $item; break }
                    if ($item -ne $null -and ($item.PSObject.Properties.Name -contains 'LogPath')) { $found = $item; break }
                } catch { }
            }
            if ($found -ne $null) { $LogContext = $found } elseif ($LogContext.Count -gt 0) { $LogContext = $LogContext[0] } else { $LogContext = $null }
        }
    if ($null -ne $LogContext) {
        if ($LogContext -is [System.Collections.IDictionary] -and $LogContext.ContainsKey('LogPath')) {
            $targetPath = $LogContext['LogPath']
        } elseif ($LogContext -ne $null -and ($LogContext.PSObject.Properties.Name -contains 'LogPath')) {
            $targetPath = $LogContext.LogPath
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