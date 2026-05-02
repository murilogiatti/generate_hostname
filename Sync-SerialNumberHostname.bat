@echo off
setlocal

:: Administrative privileges check
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Elevado: Iniciando script...
) else (
    echo Permissões de administrador necessárias. Solicitando elevação...
    powershell.exe -Command "Start-Process '%~f0' -ArgumentList '%*' -Verb runAs"
    exit /b
)

echo Este script alterara o nome do seu computador para o Serial Number (Service Tag).
choice /M "Deseja continuar?"
if %errorlevel% neq 1 (
    echo Operacao cancelada.
    exit /b
)

:: Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Sync-SerialNumberHostname.ps1" %*

endlocal
