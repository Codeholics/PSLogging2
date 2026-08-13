# Path to the Functions directory
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
Get-ChildItem -Path $functionPath -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}