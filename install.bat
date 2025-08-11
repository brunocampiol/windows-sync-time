@echo off
cd /d "%~dp0"
echo Installing Windows Time Sync components...

:: Copy PowerShell script to local app data
copy /Y "sync-time.ps1" "%LOCALAPPDATA%\sync-time.ps1"

:: Remove existing task if it exists (suppress errors with 2>nul)
schtasks /delete /tn "\Sync Time From Internet" /f 2>nul

:: Import scheduled task
schtasks /create /xml "Sync Time From Internet.xml" /tn "\Sync Time From Internet"

if %ERRORLEVEL% EQU 0 (
    echo Installation completed successfully!
) else (
    echo Installation failed with error %ERRORLEVEL%
)

pause