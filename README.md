# Windows Time Sync

A simple utility to keep your Windows system time synchronized with internet time servers.

## Components

- `sync-time.ps1`: PowerShell script that performs the time synchronization
- `Sync Time From Internet.xml`: Windows Task Scheduler configuration
- `install.bat`: Installation script

## Installation

1. Download all files to a local folder
2. Right-click `install.bat` and select "Run as administrator"
3. The installer will:
   - Copy the sync script to your local AppData folder
   - Create a scheduled task that runs at logon

## How it Works

The scheduled task runs at user logon and executes the PowerShell script to synchronize your system time with internet time servers. The task runs with system privileges to ensure it has the necessary permissions to update the time.

## Requirements

- Windows 10 or later
- Administrative privileges (for installation)

## Uninstallation

To remove the scheduled task:

```cmd
schtasks /delete /tn "\Sync Time From Internet" /f
```

To remove the script:

```cmd
del "%ProgramData%\sync-time.ps1"
```

## Security Note

The scheduled task runs with SYSTEM privileges to ensure proper time synchronization capabilities. The installation batch file must be run as administrator to set up the task correctly.
