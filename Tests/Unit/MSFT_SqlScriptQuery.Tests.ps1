<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlScriptQuery DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlScriptQuery'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'SqlServerDscHelper.psm1')

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    Add-Type -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Global -Force
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}


# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        InModuleScope 'SqlServerDscHelper' {
            $script:dscModuleName = 'SqlServerDsc'
            $resourceName = 'MSFT_SqlScriptQuery'

            $testParameters = @{
                ServerInstance = $env:COMPUTERNAME
                GetQuery       = "GetQuery;"
                TestQuery      = "TestQuery;"
                SetQuery       = "SetQuery;"
            }

            $testParametersTimeout = @{
                ServerInstance = $env:COMPUTERNAME
                GetQuery       = "GetQuery;"
                TestQuery      = "TestQuery;"
                SetQuery       = "SetQuery;"
                QueryTimeout   = 30
            }

            Describe "$resourceName\Get-TargetResource" {

                Context 'Get-TargetResource fails to import SQLPS module' {
                    $throwMessage = "Failed to import SQLPS module."

                    Mock -CommandName Import-SQLPSModule -MockWith {
                        throw $throwMessage
                    }

                    It 'Should throw the correct error from Import-Module' {
                        { Get-TargetResource @testParameters } | Should -Throw $throwMessage
                    }
                }

                Context 'Get-TargetResource returns script results successfully' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        return ''
                    }

                    It 'Should return the expected results' {
                        $result = Get-TargetResource @testParameters

                        $result.ServerInstance | Should -Be $testParameters.ServerInstance
                        $result.GetQuery | Should -Be $testParameters.GetQuery
                        $result.SetQuery | Should -Be $testParameters.SetQuery
                        $result.TestQuery | Should -Be $testParameters.TestQuery
                        $result | Should BeOfType Hashtable
                    }
                }

                Context 'Get-TargetResource returns script results successfully with query timeout' {
                    Mock -CommandName Import-SQLPSModule
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        return ''
                    }

                    It 'Should return the expected results' {
                        $result = Get-TargetResource @testParametersTimeout
                        $result.ServerInstance | Should -Be $testParametersTimeout.ServerInstance
                        $result.GetQuery | Should -Be $testParameters.GetQuery
                        $result.SetQuery | Should -Be $testParameters.SetQuery
                        $result.TestQuery | Should -Be $testParameters.TestQuery
                        $result | Should BeOfType Hashtable
                    }
                }

                Context 'Get-TargetResource throws an error when running the script in the GetQuery parameter' {
                    $errorMessage = "Failed to run SQL Script"

                    Mock -CommandName Import-SQLPSModule
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        throw $errorMessage
                    }

                    It 'Should throw the correct error from Invoke-Sqlcmd' {
                        { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                    }
                }
            }

            Describe "$resourceName\Set-TargetResource" {

                Context 'Set-TargetResource fails to import SQLPS module' {
                    $throwMessage = "Failed to import SQLPS module."

                    Mock -CommandName Import-SQLPSModule -MockWith { throw $throwMessage }

                    It 'Should throw the correct error from Import-Module' {
                        { Set-TargetResource @testParameters } | Should -Throw $throwMessage
                    }
                }

                Context 'Set-TargetResource runs script without issue' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        return ''
                    }

                    It 'Should return the expected results' {
                        $result = Set-TargetResource @testParameters
                        $result | Should -Be ''
                    }
                }

                Context 'Set-TargetResource runs script without issue using timeout' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        return ''
                    }

                    It 'Should return the expected results' {
                        $result = Set-TargetResource @testParametersTimeout
                        $result | Should -Be ''
                    }
                }

                Context 'Set-TargetResource throws an error when running the script in the SetFilePath parameter' {
                    $errorMessage = "Failed to run SQL Script"

                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        throw $errorMessage
                    }

                    It 'Should throw the correct error from Invoke-Sqlcmd' {
                        { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                    }
                }
            }

            Describe "$resourceName\Test-TargetResource" {
                Context 'Test-TargetResource fails to import SQLPS module' {
                    $throwMessage = 'Failed to import SQLPS module.'

                    Mock -CommandName Import-SQLPSModule -MockWith {
                        throw $throwMessage
                    }

                    It 'Should throw the correct error from Import-Module' {
                        { Set-TargetResource @testParameters } | Should -Throw $throwMessage
                    }
                }

                Context 'Test-TargetResource runs script without issue' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {}

                    It 'Should return true' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true
                    }
                }

                Context 'Test-TargetResource runs script without issue with timeout' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {}

                    It 'Should return true' {
                        $result = Test-TargetResource @testParametersTimeout
                        $result | Should -Be $true
                    }
                }

                Context 'Test-TargetResource throws the exception SqlPowerShellSqlExecutionException when running the script in the TestFilePath parameter' {
                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        throw New-Object -TypeName Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException
                    }

                    It 'Should return false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false
                    }
                }

                Context 'Test-TargetResource throws an unexpected error when running the script in the TestFilePath parameter' {
                    $errorMessage = "Failed to run SQL Script"

                    Mock -CommandName Import-SQLPSModule -MockWith {}
                    Mock -CommandName Invoke-Sqlcmd -MockWith {
                        throw $errorMessage
                    }

                    It 'Should throw the correct error from Invoke-Sqlcmd' {
                        { Test-TargetResource @testParameters } | Should -Throw $errorMessage
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
