function Append-LogAtomic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Value,
        [int]$MaxRetries = 5,
        [int]$RetryDelayMs = 200
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$Value`r`n")

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null
                $fs.Write($bytes, 0, $bytes.Length)
                $fs.Flush()
            } finally {
                $fs.Close()
                $fs.Dispose()
            }
            return $true
        } catch [System.IO.IOException] {
            if ($i -eq ($MaxRetries - 1)) { throw }
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum ($RetryDelayMs * ($i + 1)))
        } catch {
            throw
        }
    }
}

function Initialize-LogAtomic {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][ValidateSet('Standard','Simple','Daily')][string]$Style,
        [Parameter(Mandatory=$true)][string]$HeaderTitle,
        [switch]$DisableDailySeparator,
        [int]$MaxRetries = 8,
        [int]$RetryDelayMs = 200
    )

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            try {
                if ($fs.Length -eq 0) {
                    $header = @"
***************************************************************************************************
$HeaderTitle
***************************************************************************************************
"@
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$header`r`n")
                    $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null
                    $fs.Write($bytes, 0, $bytes.Length)
                    $fs.Flush()
                } else {
                    if ($Style -eq 'Daily' -and -not $DisableDailySeparator) {
                        $DateStamp = Get-Date
                        $separator = "----- New Run at [$DateStamp] -----`r`n"
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($separator)
                        $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null
                        $fs.Write($bytes, 0, $bytes.Length)
                        $fs.Flush()
                    }
                }
            } finally {
                $fs.Close()
                $fs.Dispose()
            }
            return $true
        } catch [System.IO.IOException] {
            if ($i -eq ($MaxRetries - 1)) { throw }
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum ($RetryDelayMs * ($i + 1)))
        } catch {
            throw
        }
    }
}
