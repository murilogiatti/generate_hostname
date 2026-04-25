# Sync-SerialNumberHostname

Utilitário de função única para Windows que sincroniza automaticamente o Hostname (Nome do Computador) com o **Serial Number** (Service Tag) recuperado diretamente da BIOS do hardware.

## 🚀 Funcionalidades
- **PowerShell Nativo:** Utiliza `CIM` (Common Information Model) para máxima performance.
- **Validação Inteligente:** Detecta e aborta a execução se o Serial Number for genérico (comum em VMs ou placas-mãe sem gravação de série, ex: "Default string").
- **Segurança:** Requer privilégios administrativos e valida o estado atual antes de tentar renomear.

## 🛠️ Como Usar

### Opção 1: Execução Local
1. Abra o PowerShell como **Administrador**.
2. Execute o script:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; .\Sync-SerialNumberHostname.ps1
   ```

### Opção 2: Linha Única (Oneliner) para Automação
Ideal para scripts de implantação (Deployment) ou RMM:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "Sync-SerialNumberHostname.ps1"
```

## 📋 Requisitos
- Windows 10 ou 11.
- PowerShell 5.1 ou PowerShell Core.
- Privilégios de Administrador.

## 📝 Licença
Este projeto é de domínio público.
