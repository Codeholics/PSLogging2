function Normalize-EmailTo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$EmailTo
    )

    # Return a string[] of addresses. Accepts a comma-separated string or an array.
    if ($EmailTo -is [string]) {
        return ($EmailTo -split '\s*,\s*') | Where-Object { $_ -and ($_.Trim().Length -gt 0) }
    } elseif ($EmailTo -is [System.Array]) {
        return $EmailTo | ForEach-Object { $_.ToString() } | Where-Object { $_ -and ($_.Trim().Length -gt 0) }
    } else {
        return @($EmailTo.ToString())
    }
}
