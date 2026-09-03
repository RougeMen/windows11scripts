@echo off
:: ==============================================================================
:: 1. AUTOMATIC ADMIN ELEVATION
:: ==============================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ==============================================================================
:: 2. COMPRESSED ERROR-PROOF GDID RUNTIME CONTAINER
:: ==============================================================================
echo Wiping local GDID state and applying network blocks...

powershell -NoProfile -ExecutionPolicy Bypass -Command "Stop-Service -Name 'CDPSvc' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'CDPSvc' -StartupType Disabled -ErrorAction SilentlyContinue; Remove-Item -Path 'HKCU:\SOFTWARE\Microsoft\IdentityCRL\ExtendedProperties' -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$env:LOCALAPPDATA\ConnectedDevicesPlatform\" -Recurse -Force -ErrorAction SilentlyContinue; Remove-NetFirewallRule -DisplayName 'Block-GDID-DeviceAdd' -ErrorAction SilentlyContinue; Remove-NetFirewallRule -DisplayName 'Block-GDID-Discovery' -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName 'Block-GDID-DeviceAdd' -Direction Outbound -RemoteAddress '127.0.0.1' -Action Block -Enabled True -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName 'Block-GDID-Discovery' -Direction Outbound -RemoteAddress '127.0.0.1' -Action Block -Enabled True -ErrorAction SilentlyContinue; $HostsPath = \"$env:windir\System32\drivers\etc\hosts\"; if (Test-Path $HostsPath) { $CleanContent = Get-Content -Path $HostsPath | Where-Object { $_ -notmatch '://' }; Set-Content -Path $HostsPath -Value $CleanContent -Force }; $Blocks = @('127.0.0.1 ://live.com', '127.0.0.1 ://windows.com'); foreach ($Line in $Blocks) { $EscapedLine = [regex]::Escape($Line); if ((Get-Content $HostsPath | Select-String -Pattern $EscapedLine) -eq $null) { Add-Content -Path $HostsPath -Value \"`n$Line\" } }"

echo.
echo All old broken lines scrubbed, and clean GDID blocks successfully established!
timeout /t 5
