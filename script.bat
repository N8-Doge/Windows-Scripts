@echo off
rem Run as admin
net sessions
if %errorlevel%==1 (
echo No admin, please run with Administrative rights...
pause
exit
)
powershell set-executionpolicy remotesigned -scope CurrentUser -force
start powershell .\main.ps1
