<#
.SYNOPSIS
    Append a warning message to the current log file.

.DESCRIPTION
    Writes a warning-level message to the log initialized by `Start-Log`.
    Supports optional timestamping and writing to the host.

.PARAMETER Message
    The warning message text to append.

.PARAMETER TimeStampFront
    When specified, place the timestamp at the beginning of the message.

.PARAMETER TimeStampBack
    When specified, place the timestamp at the end of the message.

.PARAMETER ToScreen
    When specified, also write the formatted warning to the host.

.EXAMPLE
    Write-LogWarning -Message 'Configuration deprecated' -TimeStampBack
#>
function Write-LogWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [ValidateSet('Front','Back','None')]
        [string]$TimestampPosition = 'None',
        [switch]$ToScreen
    )

    $targetPath = $script:currentLogPath

    if ($TimestampPosition -ne 'None') {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($TimestampPosition -eq 'Front') { $line = "WARNING: $ts $Message" } else { $line = "WARNING: $Message $ts" }
    } else {
        $line = "WARNING: $Message"
    }

    if ($ToScreen) { Write-Host $line -ForegroundColor Yellow }

    if ($null -ne $targetPath) {
        try {
            Append-LogAtomic -Path $targetPath -Value $line -MaxRetries 8 -RetryDelayMs 200 | Out-Null
        } catch {
            Write-Warning "Failed to append warning to log: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Cannot write warning to log. Path is null."
    }
}