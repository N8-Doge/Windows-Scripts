@echo off
rem Run as admin
net sessions
if %errorlevel%==0 (
echo Success!
) else (
echo No admin, please run with Administrative rights...
pause
exit
)
powershell set-executionpolicy remotesigned
start powershell .\main.ps1