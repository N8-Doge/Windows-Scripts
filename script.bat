@echo off
net session >nul 2>&1
if %errorlevel%==2 (
    powershell start %0 %cd% -verb runas
    exit
)
powershell set-executionpolicy remotesigned -scope CurrentUser -force
cd %1
start powershell -noexit .\main.ps1 %1
