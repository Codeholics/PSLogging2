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
#>
function Start-Log {
    Param(
        [string]$LogDir = (Join-Path -Path $PSScriptRoot -ChildPath "log"),
        [Parameter(Mandatory=$true)]
        [ValidateSet("Standard", "Simple", "Daily")]
        [string]$Style, # Accepts "Standard" or "Simple"
        [string]$Title = "Script Log",
        [switch]$ToScreen,
        [string]$Version,
        [switch]$DisableDailySeparator
    )

    # Initialize Timer
    $script:LogStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $DateStamp = Get-Date

    if ($Style -eq "Standard") {
        # Use a single date object to construct the path string for cleaner code
        $pathParts = @(
            $DateStamp.ToString("yyyy"), 
            $DateStamp.ToString("yyyy-MM"), 
            $DateStamp.ToString("yyyy-MM-dd_HHmmss")
        )
        $script:currentLogPath = Join-Path -Path $logDir -ChildPath "$($pathParts[0])\$($pathParts[1])\$($pathParts[2]).log"
    } elseif ($Style -eq "Simple") {
        $script:currentLogPath = Join-Path -Path $logDir -ChildPath "$($DateStamp.ToString('yyyy-MM-dd_HHmmss')).log"
    } elseif ($Style -eq "Daily") {
            $pathParts = @(
            $DateStamp.ToString("yyyy"), 
            $DateStamp.ToString("yyyy-MM"),
            $DateStamp.ToString("yyyy-MM-dd")
        )
        $script:currentLogPath = Join-Path -Path $logDir -ChildPath "$($pathParts[0])\$($pathParts[1])\$($pathParts[2]).log"
    } else {
        throw "Invalid Selection (Must choose style as standard, Simple, or Daily)"
    }

    # We use one consistent variable: currentLogPath
    $logPath = $script:currentLogPath

    try {
        $parentDir = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory | Out-Null
        }

        $fileExists = Test-Path -Path $logPath
        if (-not $fileExists) {
            New-Item -Path $logPath -ItemType File | Out-Null
        }
    } catch {
        Write-Error "Failed to initialize log path at $logPath. Error: $($_.Exception.Message)"
    }

    try {
        ## Start Log Header
        if ($null -eq $Version) {
            $HeaderTitle = "$Title - [$DateStamp]"
        } else {
            $HeaderTitle = "$Title ($($Version)) - [$DateStamp]"
        }

        # If the file already exists and we're in Daily mode, append a concise run separator
        if (-not $fileExists) {
            $header = @"
***************************************************************************************************
$HeaderTitle
***************************************************************************************************
"@
            Add-Content -Path $logPath -Value "$header`n" -Encoding UTF8
        } else {
            if ($Style -eq 'Daily' -and -not $DisableDailySeparator) {
                $separator = "----- New Run at [$DateStamp] -----"
                Add-Content -Path $logPath -Value "$separator`n" -Encoding UTF8
            } else {
                # existing file and separator disabled or not Daily - do nothing
            }
        }
    } catch {
        Write-Error "Failed to write initial headers: $($_.Exception.Message)"
    }

    if ($ToScreen) {
        Write-Host "Log Created: [$($logPath)] | Date: [$($DateStamp)]" -ForegroundColor Cyan
    }
}