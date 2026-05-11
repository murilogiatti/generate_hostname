Describe "Set-HostnameFromSerial" {
    BeforeAll {
        # Import the script to access the function
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
            # Mock current hostname to be different from any valid test serial
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_ComputerSystem') {
                    return [PSCustomObject]@{ Name = "OLD-NAME" }
                }
            }
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
                    if ($ClassName -eq 'Win32_BIOS') {
                        return [PSCustomObject]@{ SerialNumber = $case.Serial }
                    }
                    if ($ClassName -eq 'Win32_ComputerSystem') {
                        return [PSCustomObject]@{ Name = "OLD-NAME" }
                    }
                }

                Set-HostnameFromSerial

                Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like $case.Error }
                Should -Invoke Rename-Computer -Times 0
            }
        }

        It "Should not change hostname if it is already correct" {
            $serial = "XYZ123"
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_BIOS') {
                    return [PSCustomObject]@{ SerialNumber = $serial }
                }
                if ($ClassName -eq 'Win32_ComputerSystem') {
                    return [PSCustomObject]@{ Name = $serial }
                }
            }

            Set-HostnameFromSerial
            Should -Invoke Rename-Computer -Times 0
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

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: CIM Failure*" }
        }

        It "Should catch and report exceptions from Rename-Computer" {
            $serial = "VALID-SERIAL"
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_BIOS') { return [PSCustomObject]@{ SerialNumber = $serial } }
                if ($ClassName -eq 'Win32_ComputerSystem') { return [PSCustomObject]@{ Name = "DIFFERENT-NAME" } }
            }
            
            Mock Rename-Computer { throw "Rename Failure" }

            Set-HostnameFromSerial
            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: Rename Failure*" }
        }
    }

    Context "Successful Rename and Restart logic" {
        BeforeEach {
            $mockPrincipal = [PSCustomObject]@{ IsInRole = { return $true } }
            Mock New-Object { return $mockPrincipal }
            Mock Write-Host { }
            Mock Rename-Computer { }
            Mock Restart-Computer { }
        }

        It "Should call Rename-Computer and NOT restart by default" {
            $serial = "VALID-SERIAL-1"
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_BIOS') { return [PSCustomObject]@{ SerialNumber = $serial } }
                if ($ClassName -eq 'Win32_ComputerSystem') { return [PSCustomObject]@{ Name = "OLD-NAME" } }
            }

            Set-HostnameFromSerial

            Should -Invoke Rename-Computer -Times 1 -ParameterFilter { $NewName -eq $serial -and $Force -eq $true }
            Should -Invoke Restart-Computer -Times 0
        }

        It "Should call Rename-Computer and Restart when -Restart switch is used" {
            $serial = "VALID-SERIAL-2"
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_BIOS') { return [PSCustomObject]@{ SerialNumber = $serial } }
                if ($ClassName -eq 'Win32_ComputerSystem') { return [PSCustomObject]@{ Name = "OLD-NAME" } }
            }

            Set-HostnameFromSerial -Restart

            Should -Invoke Rename-Computer -Times 1 -ParameterFilter { $NewName -eq $serial -and $Force -eq $true }
            Should -Invoke Restart-Computer -Times 1 -ParameterFilter { $Force -eq $true }
        }
    }
}
