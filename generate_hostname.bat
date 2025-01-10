@echo off
setlocal enabledelayedexpansion

:: Check for elevated permissions
openfiles >nul 2>&1
if "%errorlevel%" NEQ "0" (
    echo Requesting administrative privileges...
    powershell -command "Start-Process '%0' -Verb runAs"
    exit /b
)

:: Generates a random LAPTOP-XXXXXXX hostname in line with Windows 7, Windows 10
:: The returned hostname is not terminated by a newline so it can be used for variables.
::
::   see: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc749460(v=ws.10)
::
:: usage: random_windows_hostname
::   out: LAPTOP-V1XZZQ3

:random_windows_hostname
set "charset=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "hostname=LAPTOP-"
for /L %%i in (1,1,7) do (
  set /A "index=!random! %% 36"
  for %%C in (!index!) do (
    set "char=!charset:~%%C,1!"
    if not defined char (
      echo Error: Invalid character index %%C
      exit /b 1
    )
    set "hostname=!hostname!!char!"
  )
)
echo !hostname!
set "new_hostname=!hostname!"

:: Setting the hostname
wmic computersystem where name="%computername%" call rename name="%new_hostname%" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Error: Failed to change hostname
    exit /b 1
)
echo Hostname changed to: %new_hostname%
pause
exit /b

:: Example usage
call :random_windows_hostname
pause
