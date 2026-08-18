function Resolve-LogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]
        $LogContext,
        [Parameter(Mandatory=$false)]
        [string]
        $LogPath
    )

    # Resolve LogPath from a provided LogContext or explicit LogPath.
    if ($null -ne $LogContext) {
        if ($LogContext -is [System.Collections.IDictionary] -and $LogContext.ContainsKey('LogPath')) {
            return $LogContext['LogPath']
        } elseif ($null -ne $LogContext -and ($LogContext.PSObject.Properties.Name -contains 'LogPath')) {
            return $LogContext.LogPath
        } else {
            throw (New-LogExceptionMessage -FunctionName 'Resolve-LogPath' -Reason 'Invalid LogContext' -InnerMessage 'LogContext must include a LogPath property')
        }
    }

    if ($PSBoundParameters.ContainsKey('LogPath') -and $LogPath) {
        return $LogPath
    }

    throw (New-LogExceptionMessage -FunctionName 'Resolve-LogPath' -Reason 'Missing parameters' -InnerMessage 'Either -LogContext or -LogPath is required')
}
