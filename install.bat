@echo off
cd /d "%~dp0"
echo Installing Windows Time Sync components...

:: Copy PowerShell script to local app data
copy /Y "sync-time.ps1" "%LOCALAPPDATA%\sync-time.ps1"

:: Import scheduled task
schtasks /create /xml "Sync Time From Internet.xml" /tn "\Sync Time From Internet"

echo Installation complete!
pause