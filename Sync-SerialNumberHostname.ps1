<#
.SYNOPSIS
    Sincroniza o Hostname do Windows com o Serial Number (Tag de Serviço) do hardware.

.DESCRIPTION
    Este script recupera o número de série da BIOS via CIM (Common Information Model),
    valida a string e altera o nome do computador. Requer privilégios administrativos.

.NOTES
    Autor: Orion (Gemini CLI)
    Versão: 1.0
#>

Function Set-HostnameFromSerial {
    [CmdletBinding()]
    Param()

    Process {
        # 1. Verificação de privilégios administrativos
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "Este script deve ser executado como Administrador."
            return
        }

        Write-Host "🔍 Recuperando Serial Number do hardware..." -ForegroundColor Cyan
        
        try {
            # 2. Captura o Serial Number (Win32_BIOS)
            $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
            $serial = $bios.SerialNumber
            if ($null -ne $serial) {
                $serial = $serial.Trim()
            }

            # 3. Validação de Serial Number inválido/genérico
            # Optimization: Using a Hashtable for O(1) lookup performance instead of an array.
            $invalidSerials = @{
                ""                       = $true
                "Default string"         = $true
                "0123456789"             = $true
                "To be filled by O.E.M." = $true
            }
            if ($null -eq $serial -or $invalidSerials.ContainsKey($serial)) {
                Write-Error "Serial Number inválido ou genérico detectado ('$serial'). O hostname não será alterado."
                return
            }

            # 3.1. Validação de formato e comprimento do Hostname (RFC 1123 + NetBIOS limit)
            if ($serial.Length -gt 15) {
                Write-Error "Serial Number muito longo ($($serial.Length) caracteres). O hostname do Windows deve ter no máximo 15 caracteres."
                return
            }

            if ($serial -notmatch '\A[a-zA-Z0-9]([a-zA-Z0-9-]{0,13}[a-zA-Z0-9])?\z') {
                Write-Error "Serial Number contém caracteres inválidos ou formato inválido para hostname ('$serial')."
                return
            }

            # 3.1. Validação de formato e comprimento do Hostname (RFC 1123 + NetBIOS limit)
            if ($serial.Length -gt 15) {
                Write-Error "Serial Number muito longo ($($serial.Length) caracteres). O hostname do Windows deve ter no máximo 15 caracteres."
                return
            }

            if ($serial -notmatch '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,13}[a-zA-Z0-9])?$') {
                Write-Error "Serial Number contém caracteres inválidos ou formato inválido para hostname ('$serial')."
                return
            }

            $currentHostname = $env:COMPUTERNAME
            if ($currentHostname -eq $serial) {
                Write-Host "✅ O hostname já está sincronizado com o Serial Number ($serial)." -ForegroundColor Green
                return
            }

            # 4. Alteração do Hostname
            Write-Host "🚀 Alterando hostname: $currentHostname -> $serial" -ForegroundColor Yellow
            Rename-Computer -NewName $serial -Force -ErrorAction Stop

            Write-Host "✨ Nome alterado com sucesso para: $serial" -ForegroundColor Green

            # 5. Solicitação de Reinicialização
            Write-Host ""
            $caption = "Reinicialização Necessária"
            $message = "O computador precisa ser reiniciado para aplicar o novo hostname ($serial). Deseja reiniciar agora?"
            $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
                New-Object System.Management.Automation.Host.ChoiceDescription "&Sim", "Reinicia o computador imediatamente."
                New-Object System.Management.Automation.Host.ChoiceDescription "&Não", "O usuário reiniciará manualmente mais tarde."
            )

            $result = $Host.UI.PromptForChoice($caption, $message, $choices, 0)

            if ($result -eq 0) {
                Write-Host "🔄 Reiniciando..." -ForegroundColor Cyan
                Restart-Computer -Force
            } else {
                Write-Host "⚠️ Lembre-se de reiniciar manualmente para aplicar as alterações." -ForegroundColor Magenta
            }

        } catch {
            Write-Error "Falha crítica ao tentar alterar o hostname: $($_.Exception.Message)"
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Set-HostnameFromSerial
}
