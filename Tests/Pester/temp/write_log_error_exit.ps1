$moduleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\\..\\..')).Path
Import-Module (Join-Path $moduleRoot 'PSLogging2.psm1') -Force
Start-Log -Style Simple -LogDir 'E:\Code\Repos\PSLogging2\Tests\Pester\temp\logs2' -Title 'Pester WriteLogError Test' -ToScreen
Write-LogError -Message 'fatal' -TimestampPosition Back -ExitGracefully
