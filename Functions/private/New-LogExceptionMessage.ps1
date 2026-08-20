function New-LogExceptionMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FunctionName,
        [Parameter(Mandatory=$true)][string]$Reason,
        [string]$InnerMessage,
        [string]$Path
    )

    if ($InnerMessage) {
        if ($Path) { return "${FunctionName}: ${Reason} [Path: $Path]. ${InnerMessage}" }
        return "${FunctionName}: ${Reason}. ${InnerMessage}"
    }

    if ($Path) { return "${FunctionName}: ${Reason} [Path: $Path]." }

    return "${FunctionName}: ${Reason}."
}
