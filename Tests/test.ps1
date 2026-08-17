$CPScriptRoot = (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path -Path $CPScriptRoot -ChildPath "PSLogging2.psm1") -Force

Start-Log `
    -Style "Standard" `
    -Title "Sample Logging Test" `
    -LogDir (Join-Path -Path $CPScriptRoot -ChildPath "log") `
    -ToScreen `
    -Version "1.0"

Write-LogInfo -Message "This was a test" -ToScreen
Write-LogInfo -Message "Another test message" -ToScreen -TimestampPosition Back
Write-LogInfo -Message "Another test message" -ToScreen -TimestampPosition Front
Write-LogInfo -Message "Another test message" -ToScreen -TimestampPosition Front

Write-LogError -message "hello" -TimestampPosition Back -ToScreen
Write-LogError -message "hello" -TimestampPosition Front -ToScreen
Write-LogError -message "hello" -TimestampPosition Back -ToScreen

Write-LogError -message "hello" -TimestampPosition Back -ToScreen -ExitGracefully

Write-LogWarning -Message "This is a warning" -TimestampPosition 'back' -ToScreen
# Send-Log -SMTPServer "smtp.example.com" -LogPath (Join-Path $PSScriptRoot 'log\2026\2026-08\A.log') -EmailFrom "me@example.com" -EmailTo "you@example.com" -EmailSubject "Log test"




Stop-Log