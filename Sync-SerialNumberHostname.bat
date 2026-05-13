@echo off
setlocal

:: Administrative privileges check
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Elevado: Iniciando script...
) else (
    echo Permissões de administrador necessárias. Solicitando elevação...
    set "SCRIPT_PATH=%~f0"
    set "SCRIPT_ARGS=%*"
    powershell.exe -NoProfile -Command "Start-Process -FilePath $env:SCRIPT_PATH -ArgumentList $env:SCRIPT_ARGS -Verb RunAs"
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
