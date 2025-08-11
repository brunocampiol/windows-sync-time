#Requires -RunAsAdministrator
<#
.SYNOPSIS
Synchronizes local system time with NTP servers (UTC-3, no DST)

.DESCRIPTION
1. Requires administrator privileges
2. Uses built-in .NET methods for NTP communication
3. Sets time with second-level precision
4. Maintains existing time zone settings (UTC-3 hardcoded)
5. Provides verbose error handling
#>

param (
    [string]$NTPServer = "pool.ntp.org"  # Default NTP pool (can be changed)
)

#region Initial Checks
# Admin check
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
if (-not ([Security.Principal.WindowsPrincipal]$currentUser).IsInRole($adminRole)) {
    Write-Error "PLEASE RUN AS ADMINISTRATOR! Right-click -> 'Run as administrator'"
    exit 1
}

# Network connectivity check with timeout
try {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $result = $ping.Send($NTPServer, 2000)  # 2000ms = 2 seconds timeout
    if ($result.Status -ne 'Success') {
        Write-Error "Network unavailable or NTP server unreachable: $NTPServer"
        exit 1
    }
}
catch {
    Write-Error "Network connectivity test failed: $_"
    exit 1
}

#region NTP Time Fetch
function Get-NtpTime {
    param(
        [string]$Server,
        [switch]$WarmupOnly
    )
    
    try {
        $endpoint = [System.Net.Dns]::GetHostEntry($Server).AddressList[0]
        $socket = New-Object System.Net.Sockets.Socket(
            [System.Net.Sockets.AddressFamily]::InterNetwork,
            [System.Net.Sockets.SocketType]::Dgram,
            [System.Net.Sockets.ProtocolType]::Udp
        )
        $socket.ReceiveTimeout = 2000
        $socket.SendTimeout = 2000
        
        # Construct NTP request
        $ntpData = [byte[]]::new(48)
        $ntpData[0] = 0x1B  # NTP client mode (version 3)
        
        # Send/receive data
        $socket.Connect($endpoint, 123)
        [void]$socket.Send($ntpData)
        [void]$socket.Receive($ntpData)
        
        if ($WarmupOnly) {
            return
        }
        
        # Convert timestamp (big-endian)
        $intPart = [BitConverter]::ToUInt32($ntpData[43..40], 0)
        $fracPart = [BitConverter]::ToUInt32($ntpData[47..44], 0)
        
        # Calculate milliseconds since 1900
        $ms = ($intPart * 1000) + ($fracPart * 1000 / 4294967296)
        
        # Convert to UTC DateTime
        $ntpEpoch = New-Object System.DateTime(1900, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)
        return $ntpEpoch.AddMilliseconds($ms)
    }
    catch {
        if (-not $WarmupOnly) {
            Write-Error "NTP communication failed: $_"
            exit 1
        }
    }
    finally {
        if ($socket) { 
            $socket.Close() 
            $socket.Dispose()
        }
    }
}

Write-Host "Warming up NTP connection..." -ForegroundColor Cyan
# Perform 3 warmup requests to stabilize the network route
1..3 | ForEach-Object {
    Get-NtpTime -Server $NTPServer -WarmupOnly
    Start-Sleep -Milliseconds 100
    Write-Verbose "Warmup request $_ completed" -Verbose
}

Write-Host "Fetching time from $NTPServer..." -ForegroundColor Cyan
# Now get the actual time after warmup
$utcTime = Get-NtpTime -Server $NTPServer
Write-Verbose "Received UTC time: $($utcTime.ToString('o'))" -Verbose
#endregion

#region Time Adjustment
# Convert to UTC-3 (hardcoded offset)
$localTime = $utcTime.AddHours(-3)
Write-Verbose "Adjusted local time (UTC-3): $($localTime.ToString('o'))" -Verbose

# Set system time
try {
    Set-Date -Date $localTime
    Write-Host "Success! Time updated to: $($localTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
}
catch {
    Write-Error "Time set failed: $_"
    exit 1
}
#endregion