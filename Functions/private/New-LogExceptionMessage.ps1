function New-LogExceptionMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FunctionName,
        [Parameter(Mandatory=$true)][string]$Reason,
        [string]$InnerMessage
    )

    if ($InnerMessage) {
        return "${FunctionName}: ${Reason}. ${InnerMessage}"
    }

    return "${FunctionName}: ${Reason}."
}
