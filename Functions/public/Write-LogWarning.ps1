<#
.SYNOPSIS
    Append a warning message to the current log file.

.DESCRIPTION
    Writes a warning-level message to the log initialized by `Start-Log`.
    Supports optional timestamping and writing to the host.

.PARAMETER Message
    The warning message text to append.

.PARAMETER TimestampPosition
    Controls timestamp placement. Accepts `Front`, `Back`, or `None` (default).

.PARAMETER TimeStampFront
    (Deprecated) Old switch. Use `-TimestampPosition Front` instead.

.PARAMETER TimeStampBack
    (Deprecated) Old switch. Use `-TimestampPosition Back` instead.

.PARAMETER ToScreen
    When specified, also write the formatted warning to the host.

.EXAMPLE
    Write-LogWarning -Message 'Configuration deprecated' -TimestampPosition Back
#>
function Write-LogWarning {
    [CmdletBinding()]
    param(
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

    try {
        $targetPath = Resolve-LogPath -LogContext $LogContext -LogPath $LogPath
    } catch {
        throw (New-LogExceptionMessage -FunctionName 'Write-LogWarning' -Reason 'Invalid or missing LogPath' -InnerMessage $_.Exception.Message)
    }

    if ($TimestampPosition -ne 'None') {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($TimestampPosition -eq 'Front') { $line = "WARNING: $ts $Message" } else { $line = "WARNING: $Message $ts" }
    } else {
        $line = "WARNING: $Message"
    }

    if ($ToScreen) { Write-Host $line -ForegroundColor Yellow }

    try {
        Append-LogAtomic -Path $targetPath -Value $line | Out-Null
    } catch {
        throw (New-LogExceptionMessage -FunctionName 'Write-LogWarning' -Reason 'Failed to append warning to log' -InnerMessage $_.Exception.Message -Path $targetPath)
    }
}