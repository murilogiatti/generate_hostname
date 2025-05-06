@echo off
:: Check for elevated permissions
echo Checking for elevated permissions...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -command "Start-Process '%0' -Verb runAs"
    exit /b
)

:: Get the system serial number using PowerShell
echo Retrieving the system serial number...
for /f %%i in ('powershell -command "Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty SerialNumber"') do (
    set "SerialNumber=%%i"
)

:: Verify if the serial number was retrieved
if "%SerialNumber%"=="" (
    echo Failed to retrieve the serial number. Exiting script.
    pause
    exit /b
)

:: Remove extra spaces
echo Cleaning up the serial number...
set "SerialNumber=%SerialNumber: =%"

:: Change the computer name using PowerShell
echo Changing the computer name to %SerialNumber%...
powershell -command "Rename-Computer -NewName '%SerialNumber%' -Force"
if %errorLevel% neq 0 (
    echo Failed to change the computer name. Exiting script.
    pause
    exit /b
)

:: Notify the user about the change
echo The computer name has been successfully changed to %SerialNumber%.

:: Ask the user if they want to restart now or later
set /p RestartNow=Do you want to restart the computer now? (Y/N): 
if /i "%RestartNow%"=="Y" (
    echo Restarting the computer now...
    shutdown /r /t 0
) else (
    echo Please restart the computer later to apply the change.
    pause
)
