@echo off
setlocal enabledelayedexpansion

:: Check for elevated permissions
openfiles >nul 2>&1
if "%errorlevel%" NEQ "0" (
    echo Requesting administrative privileges...
    powershell -command "Start-Process '%0' -Verb runAs"
    exit /b
)

:: Generates a random DESKTOP-XXXXXXX hostname in line with Windows.
:: The returned hostname is not terminated by a newline so it can be used for variables.
::
::   see: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc749460(v=ws.10)
::
:: usage: random_windows_hostname
::   out: DESKTOP-V1XZZQ3

:random_windows_hostname
set "charset=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "hostname=DESKTOP-"
for /L %%i in (1,1,7) do (
  set /A "index=!random! %% 36"
  for %%C in (!index!) do (
    set "char=!charset:~%%C,1!"
    if not defined char (
      echo Error: Invalid character index %%C
      exit /b 1
    )
    echo Index: %%C, Char: !char!
    set "hostname=!hostname!!char!"
  )
)
set "new_hostname=!hostname!"
echo New hostname generated: !new_hostname!

:: Setting the hostname
wmic computersystem where name="%computername%" call rename name="%new_hostname%" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Error: Failed to change hostname
    exit /b 1
)
echo Hostname changed to: %new_hostname%

:: Ask the user if they want to restart now or later
set /p RestartNow=Do you want to restart the computer now? (Y/N): 
if /i "%RestartNow%"=="Y" (
    shutdown /r /t 0
) else (
    echo Please restart the computer later to apply the change.
    pause
)
