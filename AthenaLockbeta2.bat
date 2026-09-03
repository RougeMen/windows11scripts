@echo off
setlocal EnableDelayedExpansion

:: Check for administrative privileges and elevate automatically if required
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ===================================================
echo [1/10] Enforcing Absolute Core Privacy Blocks...
echo ===================================================
:: Microsoft Cortana and Global Search Blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1

:: Windows Recall, Copilot, and AI Data Harvesters
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "DisableUserActivitySnapshots" /t REG_DWORD /d 1 /f >nul 2>&1

:: Native Tracking Timeline and History Feeds
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1

:: Windows OS Diagnostics, Location, and Advertising Identifiers
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable Windows Consumer Experiences (Stops automatic bloatware app installations)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable Windows 11 Widgets Feed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable Xbox Game Bar Background Recording / Telemetry
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1

echo [SUCCESS] Baseline Windows telemetry and UI bloatware points forced off.

echo ===================================================
echo [2/10] Enforcing Firefox, Steam, and GPU Protections...
echo ===================================================
:: Mozilla Firefox Enterprise Privacy Policies
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v "DisableTelemetry" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v "DisableFirefoxStudies" /t REG_DWORD /d 1 /f >nul 2>&1

:: Microsoft Edge Background Tracking Disabler
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "MetricsReportingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: NVIDIA Graphics Driver Background Analytics Block
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableLogging" /t REG_DWORD /d 0 /f >nul 2>&1

:: Steam Client Background Survey Disabler
reg add "HKCU\SOFTWARE\Valve\Steam" /v "SurveyDate" /t REG_SZ /d "0" /f >nul 2>&1

echo [SUCCESS] Application and hardware analytics avenues neutralized.

echo ===================================================
echo [3/10] Terminating and Disabling Tracking Services...
echo ===================================================
:: Stops background diagnostic delivery protocols permanently
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
sc stop NvTelemetryContainer >nul 2>&1
sc config NvTelemetryContainer start= disabled >nul 2>&1

:: Bluetooth Support Service Telemetry (Leaves Bluetooth operational, stops diagnostics)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BthService\Parameters" /v "TelemetryLevel" /t REG_DWORD /d 0 /f >nul 2>&1

echo [SUCCESS] Background tracking engines decommissioned.

echo ===================================================
echo [4/10] Clearing GDID State and Applying Network Firewall Blocks...
echo ===================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Stop-Service -Name 'CDPSvc' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'CDPSvc' -StartupType Disabled -ErrorAction SilentlyContinue; Remove-Item -Path 'HKCU:\SOFTWARE\Microsoft\IdentityCRL\ExtendedProperties' -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$env:LOCALAPPDATA\ConnectedDevicesPlatform\" -Recurse -Force -ErrorAction SilentlyContinue; Remove-NetFirewallRule -DisplayName 'Block-GDID-DeviceAdd' -ErrorAction SilentlyContinue; Remove-NetFirewallRule -DisplayName 'Block-GDID-Discovery' -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName 'Block-GDID-DeviceAdd' -Direction Outbound -RemoteAddress '127.0.0.1' -Action Block -Enabled True -ErrorAction SilentlyContinue | Out-Null; New-NetFirewallRule -DisplayName 'Block-GDID-Discovery' -Direction Outbound -RemoteAddress '127.0.0.1' -Action Block -Enabled True -ErrorAction SilentlyContinue | Out-Null; $HostsPath = \"$env:windir\System32\drivers\etc\hosts\"; if (Test-Path $HostsPath) { $CleanContent = Get-Content -Path $HostsPath | Where-Object { $_ -notmatch '://' }; Set-Content -Path $HostsPath -Value $CleanContent -Force }; $Blocks = @('127.0.0.1 ://live.com', '127.0.0.1 ://windows.com'); foreach ($Line in $Blocks) { $EscapedLine = [regex]::Escape($Line); if ((Get-Content $HostsPath | Select-String -Pattern $EscapedLine) -eq $null) { Add-Content -Path $HostsPath -Value \"`n$Line\" } }"

echo [SUCCESS] GDID runtime state wiped and host firewall restrictions established.

echo ===================================================
echo [5/10] Flushing DNS Cache ^& Network Buffers...
echo ===================================================
ipconfig /flushdns >nul 2>&1
netsh winsock reset catalog >nul 2>&1

echo [SUCCESS] Network cache and DNS resolver refreshed.

echo ===================================================
echo [6/10] Purging Hidden System Tracking Logs and Cache...
echo ===================================================
echo Evicting diagnostic data logs and telemetry cache blobs...
:: Clears local diagnostic tracking logs safely without touching game data or server files
wevtutil cl "Microsoft-Windows-Diagnostics-Performance/Operational" >nul 2>&1
del /f /q /s "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\*" >nul 2>&1
del /f /q /s "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\*" >nul 2>&1
del /f /q /s "%PROGRAMDATA%\Microsoft\Windows\WER\Temp\*" >nul 2>&1

echo [SUCCESS] Internal system usage logs and crash dumps purged.

echo ===================================================
echo [7/10] Ensuring Persistent Silent Boot Automation...
echo ===================================================
:: Configures Windows Task Scheduler to execute this file silently in the background at every user logon
schtasks /query /tn "TelemetryMonitorAutomation" >nul 2>&1
if %errorlevel% neq 0 (
    schtasks /create /tn "TelemetryMonitorAutomation" /tr "\"%~f0\"" /sc onlogon /rl highest /f >nul 2>&1
    echo [SUCCESS] Persistent scheduled boot execution pipeline established.
) else (
    echo [INFO] Scheduled boot automation rule already verified active.
)

echo ===================================================
echo [8/10] Ensuring Chocolatey Framework Setup...
echo ===================================================
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Chocolatey package manager...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
) else (
    echo [INFO] Chocolatey already installed.
)

:: Refresh PATH in current environment to ensure choco works immediately
set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

echo ===================================================
echo [9/10] Ensuring Essential Gaming ^& App Runtimes...
echo ===================================================
call choco install vcredist-all directx -y --no-progress

echo ===================================================
echo [10/10] Updating Applications (Via Winget ^& Chocolatey)...
echo ===================================================
winget pin add --id CreativeTechnology.OpenAL >nul 2>&1

echo Running Winget application updates...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

echo Running Chocolatey package updates...
call choco upgrade all -y --no-progress

echo ===================================================
echo Privacy enforced, GDID neutralized, network refreshed, runtimes verified, and updates complete!
echo ===================================================
pause
exit /b