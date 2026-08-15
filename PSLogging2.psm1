$privatePath = Join-Path $PSScriptRoot 'Functions\private'
$publicPath  = Join-Path $PSScriptRoot 'Functions\public'

if (Test-Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
}

$publicFiles = @()
if (Test-Path $publicPath) {
    $publicFiles = Get-ChildItem -Path $publicPath -Filter '*.ps1' -File
    $publicFiles | ForEach-Object { . $_.FullName }
}

if ($publicFiles) {
    Export-ModuleMember -Function ($publicFiles.BaseName)
}