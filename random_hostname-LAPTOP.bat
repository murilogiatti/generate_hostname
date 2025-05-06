@echo off
setlocal enabledelayedexpansion

:: Check for elevated permissions
echo Checking for elevated permissions...
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -command "Start-Process '%0' -Verb runAs"
    exit /b
)

:: Generate a random LAPTOP-XXXXXXX hostname
set "charset=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "hostname=LAPTOP-"
for /L %%i in (1,1,7) do (
    set /A "index=!random! %% 36"
    for %%C in (!index!) do (
        set "char=!charset:~%%C,1!"
        set "hostname=!hostname!!char!"
    )
)
set "new_hostname=!hostname!"
echo New hostname generated: !new_hostname!

:: Change the computer name using PowerShell
echo Changing the computer name to %new_hostname%...
powershell -command "Rename-Computer -NewName '%new_hostname%' -Force"

:: Verify if the rename command was successful
if %errorlevel% NEQ 0 (
    echo Error: Failed to change hostname.
    exit /b 1
)

echo Hostname changed successfully to: %new_hostname%

:: Ask the user if they want to restart now or later
set /p RestartNow=Do you want to restart the computer now? (Y/N): 
if /i "%RestartNow%"=="Y" (
    echo Restarting the computer now...
    shutdown /r /t 0
) else (
    echo Please restart the computer later to apply the change.
    pause
)
