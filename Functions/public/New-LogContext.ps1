<#
.SYNOPSIS
    Create a lightweight LogContext object for explicit logging.

.DESCRIPTION
    Returns a PSCustomObject containing `LogPath`, `Started`, and a `Stopwatch` instance.
    Use this object with writer functions via the `-LogContext` parameter.
#>
function New-LogContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath
    )

    $ctx = [PSCustomObject]@{
        LogPath = $LogPath
        Started = Get-Date
        Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }

    return $ctx
}
