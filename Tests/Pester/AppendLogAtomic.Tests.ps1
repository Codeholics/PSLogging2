Describe 'Append-LogAtomic' {

    InModuleScope PSLogging2 {

        It 'Appends text to a file' {

            $LogFile = Join-Path $TestDrive 'test.log'

            New-Item -Path $LogFile -ItemType File | Out-Null

            Append-LogAtomic `
                -Path $LogFile `
                -Value 'Hello'

            (Get-Content $LogFile) |
                Should -Contain 'Hello'
        }
    }
}