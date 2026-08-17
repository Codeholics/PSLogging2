$moduleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\\..\\..')).Path
Import-Module (Join-Path $moduleRoot 'PSLogging2.psm1') -Force
Start-Log -Style Simple -LogDir 'E:\Code\Repos\PSLogging2\Tests\Pester\temp\logs' -Title 'Pester StopLog Test' -ToScreen
Write-LogInfo -Message 'step'
Stop-Log -NoExit
Exit 0
