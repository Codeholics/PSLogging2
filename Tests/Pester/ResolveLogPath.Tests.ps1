BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot 'PSLogging2.psm1') -Force
}

Describe 'Resolve-LogPath' {

    InModuleScope PSLogging2 {

        Context 'Using -LogPath' {

            It 'Returns the provided LogPath' {

                $Path = 'C:\Temp\Test.log'

                $Result = Resolve-LogPath -LogPath $Path

                $Result | Should -Be $Path
            }
        }

        Context 'Using -LogContext' {

            It 'Returns the LogPath from a valid context object' {

                $Context = [PSCustomObject]@{
                    LogPath = 'C:\Temp\Context.log'
                }

                $Result = Resolve-LogPath -LogContext $Context

                $Result | Should -Be 'C:\Temp\Context.log'
            }
        }

        Context 'Parameter Priority' {

            It 'Prefers LogContext when both LogContext and LogPath are supplied' {

                $Context = [PSCustomObject]@{
                    LogPath = 'C:\Temp\Context.log'
                }

                $Result = Resolve-LogPath `
                    -LogContext $Context `
                    -LogPath 'C:\Temp\Other.log'

                $Result | Should -Be 'C:\Temp\Context.log'
            }
        }

        Context 'Validation' {

            It 'Throws when neither parameter is supplied' {

                {
                    Resolve-LogPath
                } | Should -Throw
            }

            It 'Throws when LogContext is null' {

                {
                    Resolve-LogPath -LogContext $null
                } | Should -Throw
            }
        }
    }
}