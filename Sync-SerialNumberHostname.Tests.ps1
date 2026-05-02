Describe "Set-HostnameFromSerial" {
    BeforeAll {
        # Import the script to access the function
        # The script has been modified to not execute when dot-sourced
        . "$PSScriptRoot/Sync-SerialNumberHostname.ps1"
    }

    Context "Administrative Privileges" {
        It "Should fail when not running as Administrator" {
            # Mock the admin check to return false
            $mockPrincipal = [PSCustomObject]@{
                IsInRole = { return $false }
            }
            Mock New-Object { return $mockPrincipal }
            Mock Write-Error { }

            Set-HostnameFromSerial

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*deve ser executado como Administrador*" }
        }
    }

    Context "Serial Number Validation" {
        BeforeEach {
            # Mock admin check to true for these tests
            $mockPrincipal = [PSCustomObject]@{
                IsInRole = { return $true }
            }
            Mock New-Object { return $mockPrincipal }
            Mock Write-Host { }
            Mock Write-Error { }
            Mock Rename-Computer { }
        }

        $invalidSerials = @(
            @{ Name = "Empty String"; Serial = ""; Error = "*inválido ou genérico*" },
            @{ Name = "Default String"; Serial = "Default string"; Error = "*inválido ou genérico*" },
            @{ Name = "Numeric Dummy"; Serial = "0123456789"; Error = "*inválido ou genérico*" },
            @{ Name = "OEM String"; Serial = "To be filled by O.E.M."; Error = "*inválido ou genérico*" },
            @{ Name = "Null Serial"; Serial = $null; Error = "*inválido ou genérico*" },
            @{ Name = "Invalid Format"; Serial = "Host_Name"; Error = "*contém caracteres inválidos*" },
            @{ Name = "Too Long"; Serial = "A1234567890123456"; Error = "*muito longo*" },
            @{ Name = "Serial with Newline"; Serial = "ABC12345678901`n"; Error = "*contém caracteres inválidos*" }
        )

        foreach ($case in $invalidSerials) {
            It "Should abort and show error for invalid serial: $($case.Name)" {
                Mock Get-CimInstance {
                    return [PSCustomObject]@{ SerialNumber = $case.Serial }
                }

                Set-HostnameFromSerial

                Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like $case.Error }
                Should -Invoke Rename-Computer -Times 0
            }
        }

        It "Should not change hostname if it is already correct" {
            $serial = "XYZ123"
            Mock Get-CimInstance { return [PSCustomObject]@{ SerialNumber = $serial } }

            # Mock environment variable
            $oldEnv = $env:COMPUTERNAME
            $env:COMPUTERNAME = $serial

            try {
                Set-HostnameFromSerial
                Should -Invoke Rename-Computer -Times 0
            }
            finally {
                $env:COMPUTERNAME = $oldEnv
            }
        }
    }

    Context "Error Handling" {
        BeforeEach {
            $mockPrincipal = [PSCustomObject]@{ IsInRole = { return $true } }
            Mock New-Object { return $mockPrincipal }
            Mock Write-Host { }
            Mock Write-Error { }
        }

        It "Should catch and report exceptions from Get-CimInstance" {
            Mock Get-CimInstance { throw "CIM Failure" }

            Set-HostnameFromSerial

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $args[0] -like "Falha crítica ao tentar alterar o hostname: CIM Failure*" }
        }

        It "Should catch and report exceptions from Rename-Computer" {
            $serial = "VALID-SERIAL"
            Mock Get-CimInstance { return [PSCustomObject]@{ SerialNumber = $serial } }
            
            # Need to set env var so it doesn't return early due to match
            $oldEnv = $env:COMPUTERNAME
            $env:COMPUTERNAME = "DIFFERENT-NAME"
            
            Mock Rename-Computer { throw "Rename Failure" }

            try {
                Set-HostnameFromSerial
                Should -Invoke Write-Error -Times 1 -ParameterFilter { $args[0] -like "Falha crítica ao tentar alterar o hostname: Rename Failure*" }
            }
            finally {
                $env:COMPUTERNAME = $oldEnv
            }
        }
    }

    Context "Successful Rename" {
        It "Should call Rename-Computer and Prompt for restart when serial is valid" {
            $serial = "VALID-SERIAL-123"
            $currentName = "OLD-NAME"

            # Mock Admin check
            $mockPrincipal = [PSCustomObject]@{ IsInRole = { return $true } }
            Mock New-Object { return $mockPrincipal }

            Mock Get-CimInstance { return [PSCustomObject]@{ SerialNumber = $serial } }
            Mock Write-Host { }
            Mock Rename-Computer { }
            Mock Restart-Computer { }

            # Mock the Host UI for Choice Prompt
            $mockHost = [PSCustomObject]@{
                UI = [PSCustomObject]@{
                    PromptForChoice = { return 1 } # Return 1 for "No"
                }
            }
            # Unfortunately mocking $Host is hard, but let's try to mock the call if possible
            # In Pester, we can sometimes mock the UI calls if they are called on $Host.UI

            # Actually, the script uses $Host.UI.PromptForChoice
            # We might need to mock the command or provide a mock host

            $oldEnv = $env:COMPUTERNAME
            $env:COMPUTERNAME = $currentName

            try {
                Set-HostnameFromSerial

                Should -Invoke Rename-Computer -Times 1 -ParameterFilter { $NewName -eq $serial -and $Force -eq $true }
            }
            finally {
                $env:COMPUTERNAME = $oldEnv
            }
        }
    }

    Context "Error Handling" {
        BeforeEach {
            # Mock Admin check
            $mockPrincipal = [PSCustomObject]@{ IsInRole = { return $true } }
            Mock New-Object { return $mockPrincipal }
            Mock Write-Host { }
            Mock Write-Error { }
        }

        It "Should catch and report exceptions from Get-CimInstance" {
            Mock Get-CimInstance { throw "CIM Failure" }

            Set-HostnameFromSerial

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: CIM Failure*" }
        }

        It "Should catch and report exceptions from Rename-Computer" {
            $serial = "NEW-SERIAL-99"
            Mock Get-CimInstance { return [PSCustomObject]@{ SerialNumber = $serial } }
            Mock Rename-Computer { throw "Rename Failure" }

            $oldEnv = $env:COMPUTERNAME
            $env:COMPUTERNAME = "DIFFERENT-NAME"

            try {
                Set-HostnameFromSerial
                Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: Rename Failure*" }
            }
            finally {
                $env:COMPUTERNAME = $oldEnv
            }
        }
    }
}
