<#
.SYNOPSIS
    Create or open a log file for this script run.

.DESCRIPTION
    Initializes logging for the calling script. Supports three styles:
    - Standard: nested year/month/run timestamped files
    - Simple: single file per run
    - Daily: one file per day (multiple runs appended to same daily file)

.PARAMETER LogDir
    Directory where logs are stored. Defaults to the module's `log` folder.

.PARAMETER Style
    One of `Standard`, `Simple`, or `Daily` to choose the file naming strategy.

.PARAMETER Title
    Human readable title used in the log header.

.PARAMETER ToScreen
    When specified, writes a short status message to the host.

.PARAMETER Version
    Optional version string to include in the log header.

.PARAMETER DisableDailySeparator
    When `-Style Daily` is used, the module by default appends a small
    run-separator line when a daily file already exists. Specify this
    switch to disable the automatic run separator.

.EXAMPLE
    Start-Log -Style Daily -LogDir .\log -Title 'MyScript' -ToScreen

.NOTES
    All files and header content are written using UTF-8 encoding.

    The cmdlet will throw on header or initialization failures so callers can
    handle failures instead of the module silently continuing.
#>
function Start-Log {
    [CmdletBinding()]
    Param(
        [string]$LogDir = (Join-Path -Path $PSScriptRoot -ChildPath "log"),
        [Parameter(Mandatory=$true)]
        [ValidateSet("Standard", "Simple", "Daily")]
        [string]$Style,
        [string]$Title = "Script Log",
        [switch]$ToScreen,
        [string]$Version,
        [switch]$DisableDailySeparator,
        [switch]$ReturnContext
    )

    # Initialize Timer
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $DateStamp = Get-Date

    if ($Style -eq "Standard") {
        # Use a single date object to construct the path string for cleaner code
        $pathParts = @(
            $DateStamp.ToString("yyyy"), 
            $DateStamp.ToString("yyyy-MM"), 
            $DateStamp.ToString("yyyy-MM-dd_HHmmss")
        )
        $logPath = Join-Path -Path $logDir -ChildPath "$($pathParts[0])\$($pathParts[1])\$($pathParts[2]).log"
    } elseif ($Style -eq "Simple") {
        $logPath = Join-Path -Path $logDir -ChildPath "$($DateStamp.ToString('yyyy-MM-dd_HHmmss')).log"
    } elseif ($Style -eq "Daily") {
            $pathParts = @(
            $DateStamp.ToString("yyyy"), 
            $DateStamp.ToString("yyyy-MM"),
            $DateStamp.ToString("yyyy-MM-dd")
        )
        $logPath = Join-Path -Path $logDir -ChildPath "$($pathParts[0])\$($pathParts[1])\$($pathParts[2]).log"
    } else {
        throw "Invalid Selection (Must choose style as standard, Simple, or Daily)"
    }

    # Use the computed log path
    # $logPath already populated above

    # Ensure the parent directory exists (fail fast on filesystem errors)
    try {
        $parentDir = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        throw (New-LogExceptionMessage -FunctionName 'Start-Log' -Reason 'Failed to create or validate log directory' -InnerMessage $_.Exception.Message -Path $logPath)
    }

    # Prepare header title
    if ($null -eq $Version) {
        $HeaderTitle = "$Title - [$DateStamp]"
    } else {
        $HeaderTitle = "$Title ($($Version)) - [$DateStamp]"
    }

    # Initialize header or separator using an exclusive lock to avoid concurrent write races
    try {
        Initialize-LogAtomic -Path $logPath -Style $Style -HeaderTitle $HeaderTitle -DisableDailySeparator:$DisableDailySeparator | Out-Null
    } catch {
        throw (New-LogExceptionMessage -FunctionName 'Start-Log' -Reason 'Failed to initialize log header/separator atomically' -InnerMessage $_.Exception.Message -Path $logPath)
    }

    if ($ToScreen) {
        Write-Host "Log Created: [$($logPath)] | Date: [$($DateStamp)]" -ForegroundColor Cyan
    }

    if ($ReturnContext) {
        $ctx = New-LogContext -LogPath $logPath
        # Preserve the start time and stopwatch initialized above
        $ctx | Add-Member -NotePropertyName Started -NotePropertyValue $DateStamp -Force
        $ctx | Add-Member -NotePropertyName Stopwatch -NotePropertyValue $stopwatch -Force
        return $ctx
    }
}