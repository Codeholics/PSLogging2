<#
.SYNOPSIS
    Generates a PSD1 file for a custom module
.DESCRIPTION
    Generates a PSD1 file for a custom module with dynamic package.
.NOTES
    Author: Codeholics - Eric Reis (https://github.com/EReis0)
    Version: 1.0
#>
$RootDir = $PSScriptRoot
$FunctionDir = Join-Path -Path $RootDir -ChildPath "Functions"
$PublicFunctionDir = Join-Path -Path $FunctionDir -ChildPath "public"
$PrivateFunctionDir = Join-Path -Path $FunctionDir -ChildPath "private"

# Get all public functions in the module
$PublicFunctions = Get-ChildItem -Path $FunctionDir -Filter *.ps1 -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName
    foreach ($item in $content) {
        if ($item -match "^function\s+([a-z]+[\w-]*)") {
            $matches[1]
        }
    }
} | Select-Object -Unique

# Get all private functions in the module
$PrivateFunctions = Get-ChildItem -Path $PrivateFunctionDir -Filter *.ps1 -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName
    foreach ($item in $content) {
        if ($item -match "^function\s+([a-z]+[\w-]*)") {
            $matches[1]
        }
    }
} | Select-Object -Unique

# Split the root directory to get the module name (last part of the path)
$ModuleName = $RootDir.Split("\")[-1]

# Create the module manifest
$ParmsModulePath = Join-Path -Path $RootDir -ChildPath "$ModuleName.psd1"
$Params = @{ 
    "Path" 				        = $ParmsModulePath
    "Author" 			        = 'Eric Reis https://github.com/EReis0' 
    "CompanyName" 			    = 'Codeholics.com (https://codeholics.com)' 
    "RootModule" 			    = "$ModuleName.psm1"
    "CompatiblePSEditions" 		= @('Desktop','Core') 
    "FunctionsToExport" 		= $PublicFunctions
    "CmdletsToExport" 		    = $PublicFunctions
    "VariablesToExport" 		= @() 
    "AliasesToExport" 		    = @() 
    "Description"               = "$ModuleName is a custom built module."
    "ModuleVersion"             = "1.0.0"
    "PowerShellVersion"         = '5.1'
    "Copyright"                 = "$(Get-Date -Format yyyy) Eric Reis. Licensed under the MIT License."
} 

New-ModuleManifest @Params