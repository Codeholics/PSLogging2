# Start-Log.Tests.ps1

BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot 'PSLogging2.psm1') -Force

    $TestRoot = Join-Path $TestDrive 'Logs'
}

Describe 'Start-Log' {

    Context 'Standard Style' {

        It 'Creates a log file and returns a valid context object' {

            $ctx = Start-Log `
                -Style Standard `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $ctx | Should -Not -BeNullOrEmpty

            $ctx.LogPath | Should -Not -BeNullOrEmpty
            $ctx.Started | Should -Not -BeNullOrEmpty
            $ctx.Stopwatch | Should -Not -BeNullOrEmpty

            Test-Path $ctx.LogPath | Should -BeTrue
        }

        It 'Creates year and month folders' {

            $ctx = Start-Log `
                -Style Standard `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $parentFolder = Split-Path $ctx.LogPath -Parent

            Test-Path $parentFolder | Should -BeTrue
        }
    }

    Context 'Simple Style' {

        It 'Creates a log file' {

            $ctx = Start-Log `
                -Style Simple `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            Test-Path $ctx.LogPath | Should -BeTrue
        }

        It 'Creates the file directly beneath LogDir' {

            $ctx = Start-Log `
                -Style Simple `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            Split-Path $ctx.LogPath -Parent |
                Should -Be ([System.IO.Path]::GetFullPath($TestRoot))
        }
    }

    Context 'Daily Style' {

        It 'Creates a daily log file' {

            $ctx = Start-Log `
                -Style Daily `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            Test-Path $ctx.LogPath | Should -BeTrue
        }

        It 'Reuses the same file path on the same day' {

            $ctx1 = Start-Log `
                -Style Daily `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $ctx2 = Start-Log `
                -Style Daily `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $ctx1.LogPath | Should -Be $ctx2.LogPath
        }
    }

    Context 'Context Object' {

        It 'Returns a stopwatch object' {

            $ctx = Start-Log `
                -Style Standard `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $ctx.Stopwatch |
                Should -BeOfType ([System.Diagnostics.Stopwatch])
        }

        It 'Returns a datetime Start value' {

            $ctx = Start-Log `
                -Style Standard `
                -Title 'Pester Test' `
                -LogDir $TestRoot `
                -ReturnContext

            $ctx.Started |
                Should -BeOfType ([datetime])
        }
    }

    Context 'Header Creation' {

        It 'Writes the header to the new log file' {

            $ctx = Start-Log `
                -Style Standard `
                -Title 'My Test Script' `
                -Version '1.0' `
                -LogDir $TestRoot `
                -ReturnContext

            $content = Get-Content $ctx.LogPath -Raw

            $content | Should -Match 'My Test Script'
            $content | Should -Match '1.0'
        }
    }
}