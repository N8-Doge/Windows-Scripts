@echo off
net session >nul 2>&1
if %errorlevel%==2 (
    powershell start %0 %cd% -verb runas
    exit
)
powershell set-executionpolicy remotesigned -scope CurrentUser -force
start powershell -noexit %1\main.ps1 %1