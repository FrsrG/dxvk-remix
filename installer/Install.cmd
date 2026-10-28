@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Setup could not finish. Read the message above.
pause
exit /b %result%
