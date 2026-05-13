Describe "Set-HostnameFromSerial" {
    BeforeAll {
        # Import the script to access the function
        . "$PSScriptRoot/Sync-SerialNumberHostname.ps1"
    }

    BeforeEach {
        $script:mockSettings = @{
            IsAdmin         = $true
            SerialNumber    = "VALID-SERIAL"
            CurrentHostname = "OLD-NAME"
            CimException    = $null
            RenameException = $null
        }

        Mock New-Object {
            return [PSCustomObject]@{
                IsInRole = { param($role) return $script:mockSettings.IsAdmin }
            }
        }
        Mock Get-CimInstance {
            if ($script:mockSettings.CimException) { throw $script:mockSettings.CimException }
            if ($ClassName -eq 'Win32_BIOS') {
                return [PSCustomObject]@{ SerialNumber = $script:mockSettings.SerialNumber }
            }
            if ($ClassName -eq 'Win32_ComputerSystem') {
                return [PSCustomObject]@{ Name = $script:mockSettings.CurrentHostname }
            }
        }
        Mock Write-Host { }
        Mock Write-Error { }
        Mock Rename-Computer {
            if ($script:mockSettings.RenameException) { throw $script:mockSettings.RenameException }
        }
        Mock Restart-Computer { }
    }

    Context "Administrative Privileges" {
        It "Should fail when not running as Administrator" {
            $script:mockSettings.IsAdmin = $false

            Set-HostnameFromSerial

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*deve ser executado como Administrador*" }
        }
    }

    Context "Serial Number Validation" {
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
                $script:mockSettings.SerialNumber = $case.Serial

                Set-HostnameFromSerial

                Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like $case.Error }
                Should -Invoke Rename-Computer -Times 0
            }
        }

        It "Should not change hostname if it is already correct" {
            $serial = "XYZ123"
            $script:mockSettings.SerialNumber = $serial
            $script:mockSettings.CurrentHostname = $serial

            Set-HostnameFromSerial
            Should -Invoke Rename-Computer -Times 0
        }
    }

    Context "Error Handling" {
        It "Should catch and report exceptions from Get-CimInstance" {
            $script:mockSettings.CimException = "CIM Failure"

            Set-HostnameFromSerial

            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: CIM Failure*" }
        }

        It "Should catch and report exceptions from Rename-Computer" {
            $script:mockSettings.SerialNumber = "VALID-SERIAL"
            $script:mockSettings.CurrentHostname = "DIFFERENT-NAME"
            $script:mockSettings.RenameException = "Rename Failure"

            Set-HostnameFromSerial
            Should -Invoke Write-Error -Times 1 -ParameterFilter { $Message -like "*Falha crítica ao tentar alterar o hostname: Rename Failure*" }
        }
    }

    Context "Successful Rename and Restart logic" {
        It "Should call Rename-Computer and NOT restart by default" {
            $serial = "VALID-SERIAL-1"
            $script:mockSettings.SerialNumber = $serial
            $script:mockSettings.CurrentHostname = "OLD-NAME"

            Set-HostnameFromSerial

            Should -Invoke Rename-Computer -Times 1 -ParameterFilter { $NewName -eq $serial -and $Force -eq $true }
            Should -Invoke Restart-Computer -Times 0
        }

        It "Should call Rename-Computer and Restart when -Restart switch is used" {
            $serial = "VALID-SERIAL-2"
            $script:mockSettings.SerialNumber = $serial
            $script:mockSettings.CurrentHostname = "OLD-NAME"

            Set-HostnameFromSerial -Restart

            Should -Invoke Rename-Computer -Times 1 -ParameterFilter { $NewName -eq $serial -and $Force -eq $true }
            Should -Invoke Restart-Computer -Times 1 -ParameterFilter { $Force -eq $true }
        }
    }
}
