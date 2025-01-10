@echo off
setlocal enabledelayedexpansion

rem Generates a random LAPTOP-XXXXXXX hostname in line with Windows.
rem The returned hostname is not terminated by a newline so it can be used for variables.
rem
rem   see: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc749460(v=ws.10)
rem
rem usage: random_windows_hostname
rem   out: LAPTOP-V1XZZQ3

:random_windows_hostname
set "charset=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "hostname=LAPTOP-"
for /L %%i in (1,1,7) do (
  set /A "index=!random! %% 36"
  for %%C in (!index!) do set "hostname=!hostname!!charset:~%%C,1!"
)
echo !hostname!
set "new_hostname=!hostname!"

rem Setting the hostname
wmic computersystem where name="%computername%" call rename name="%new_hostname%"
echo Hostname changed to: %new_hostname%
exit /b

rem Example usage
call :random_windows_hostname
pause
