@echo off
rem Run as admin
net sessions 2> nul
if %errorlevel%==2 (
powershell start .\script.bat -verb runas
exit
)
powershell set-executionpolicy remotesigned -scope CurrentUser -force
start powershell .\main.ps1