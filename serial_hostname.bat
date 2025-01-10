@echo off
:: Check for elevated permissions
echo Checking for elevated permissions...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -command "Start-Process '%0' -Verb runAs"
    exit /b
)

:: Get the system serial number
echo Retrieving the system serial number...
for /f "tokens=2 delims==" %%i in ('wmic bios get serialnumber /value 2^>nul') do (
    if not "%%i"=="" (
        set "SerialNumber=%%i"
        goto :SerialFound
    )
)

:SerialFound
if "%SerialNumber%"=="" (
    echo Failed to retrieve the serial number. Exiting script.
    pause
    exit /b
)

:: Remove extra spaces
echo Cleaning up the serial number...
set "SerialNumber=%SerialNumber: =%"

:: Set the hostname
echo Changing the hostname to %SerialNumber%...
wmic computersystem where name="%computername%" call rename name="%SerialNumber%" >nul 2>&1
if %errorLevel% neq 0 (
    echo Failed to change the hostname. Exiting script.
    pause
    exit /b
)

:: Notify the user about the change
echo The hostname has been successfully changed to %SerialNumber%.

:: Ask the user if they want to restart now or later
set /p RestartNow=Do you want to restart the computer now? (Y/N): 
if /i "%RestartNow%"=="Y" (
    echo Restarting the computer now...
    shutdown /r /t 0
) else (
    echo Please restart the computer later to apply the change.
    pause
)
