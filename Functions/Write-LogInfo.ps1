<#
.SYNOPSIS
    Append an informational line to the current log file.

.DESCRIPTION
    Writes an informational message to the log initialized by `Start-Log`.
    Supports optional timestamping and writing to host output.

.PARAMETER Message
    The message text to append to the log.

.PARAMETER TimeStampFront
    When specified, place the timestamp at the beginning of the message.

.PARAMETER TimeStampBack
    When specified, place the timestamp at the end of the message.

.PARAMETER ToScreen
    When specified, also write the formatted message to the host.

.EXAMPLE
    Write-LogInfo -Message 'Processing item' -TimeStampFront
#>
function Write-LogInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        # New explicit switches for clarity
        [switch]$TimeStampFront,
        [switch]$TimeStampBack,
        [switch]$ToScreen
    )

    # Use the script scope variable that was established in Start-Log.ps1
    $targetPath = $script:currentLogPath

    # Determine effective timestamp position.
    $useFront = $false
    $useBack = $false
    if ($TimeStampFront) { $useFront = $true }
    if ($TimeStampBack) { $useBack = $true }

    if ($useFront -or $useBack) {
        $ts = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
        if ($useFront) { $formatted = "$ts $Message" } else { $formatted = "$Message $ts" }
    } else {
        $formatted = $Message
    }

    if ($ToScreen) { Write-Host $formatted -ForegroundColor Cyan }

    if ($null -ne $targetPath -and (Test-Path $targetPath)) {
        try {
            Append-LogAtomic -Path $targetPath -Value "- $($formatted)" -MaxRetries 8 -RetryDelayMs 200 | Out-Null
        } catch {
            Write-Warning "Failed to append to log: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Cannot write to log. Path is null or file does not exist."
    }
}