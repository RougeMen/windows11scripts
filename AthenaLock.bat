@echo off
setlocal EnableDelayedExpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as an Administrator.
    echo Please right-click the script and select 'Run as administrator'.
    pause
    exit /b
)

echo ===================================================
echo [1/5] Enforcing Permanent Privacy Restrictions...
echo ===================================================
:: Permanent Cortana Blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f >nul 2>&1

:: Permanent Windows Recall Blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows AI" /v "DisableUserActivitySnapshots" /t REG_DWORD /d 1 /f >nul 2>&1

:: Telemetry, Advertising ID, and Activity History Blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1

echo [2/5] Ensuring tracking services are disabled...
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1

echo [3/5] Launching secure engine for registry scanning...
echo ================================================================

:: Extract the embedded PowerShell code directly from the bottom of this file
set "TEMP_PS=%TEMP%\TelemetryEngine.ps1"
type nul > "%TEMP_PS%"

set "extract=0"
for /f "delims=" %%A in ('type "%~f0"') do (
    if "!extract!"=="1" (
        echo %%A>> "%TEMP_PS%"
    )
    if "%%A"=="===POWERSHELL_START===" set "extract=1"
)

:: Run the clean PowerShell file
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"

:: Clean up
del "%TEMP_PS%" >nul 2>&1

echo ===================================================
echo [5/5] Updating All PC Applications (Via winget)...
echo ===================================================
echo Checking for available app updates and installing them...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

echo ===================================================
echo privacy enforced and app updates completed!
echo ===================================================
pause
exit /b

===POWERSHELL_START===
$workDir = Join-Path $env:USERPROFILE 'RegistryTelemetryMonitor'
if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir | Out-Null }
$baselineFile = Join-Path $workDir 'baseline_snapshot.csv'

$paths = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search',
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows AI',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
)

$ScanRegistry = {
    $results = @()
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $keyPath = $_.Name
                foreach ($valName in $_.GetValueNames()) {
                    $valData = $_.GetValue($valName)
                    if ($valName -eq '') { $valName = '(Default)' }
                    $results += [PSCustomObject]@{ Key = $keyPath; ValueName = $valName; Data = [string]$valData }
                }
            }
            $rootKey = Get-Item -Path $p -ErrorAction SilentlyContinue
            if ($rootKey) {
                foreach ($valName in $rootKey.GetValueNames()) {
                    $valData = $rootKey.GetValue($valName)
                    if ($valName -eq '') { $valName = '(Default)' }
                    $results += [PSCustomObject]@{ Key = $rootKey.Name; ValueName = $valName; Data = [string]$valData }
                }
            }
        }
    }
    return $results
}

if (-not (Test-Path $baselineFile)) {
    Write-Host '[INFO] No baseline found. Creating secure system baseline...' -ForegroundColor Cyan
    $baseline = Invoke-Command -ScriptBlock $ScanRegistry
    $baseline | Export-Csv -Path $baselineFile -NoTypeInformation
    Write-Host '[SUCCESS] Baseline snapshot created successfully.' -ForegroundColor Green
    Write-Host '================================================================' -ForegroundColor Yellow
    return
}

Write-Host '[INFO] Scanning registry for active tracking changes...' -ForegroundColor Cyan
$currentScan = Invoke-Command -ScriptBlock $ScanRegistry
$baselineData = Import-Csv -Path $baselineFile
$changesFound = $false

foreach ($item in $currentScan) {
    # Skip checking core system privacy preferences and temporary local taskbar jump lists
    if ($item.ValueName -match 'AllowTelemetry|AllowCortana|TurnOffWindowsCopilot|DisableAIDataAnalysis|DisableUserActivitySnapshots|EnableActivityFeed|PublishUserActivities|UploadUserActivities|Enabled') {
        continue
    }
    if ($item.Key -match 'Search\\JumplistData') {
        continue
    }

    $match = $baselineData | Where-Object { $_.Key -eq $item.Key -and $_.ValueName -eq $item.ValueName -and $_.Data -eq $item.Data }
    if (-not $match) {
        $changesFound = $true
        Write-Host ''
        Write-Host '================================================================' -ForegroundColor Yellow
        Write-Host '[DETECTED CHANGE] New or Modified Tracking Value Found!' -ForegroundColor Yellow
        Write-Host ("Key Location:   " + $item.Key) -ForegroundColor White
        Write-Host ("Registry Value: " + $item.ValueName) -ForegroundColor White
        Write-Host ("Current Data:   " + $item.Data) -ForegroundColor White
        Write-Host '================================================================' -ForegroundColor Yellow
        Write-Host 'What action do you want to take?'
        Write-Host '1 - Allow   (Keep exactly as it is)'
        Write-Host '2 - Disable (Force value data to 0 to block functionality)'
        Write-Host '3 - Delete  (Permanently remove this value)'
        $choice = Read-Host 'Select an action (1-3)'
        
        $vName = if ($item.ValueName -eq '(Default)') { '' } else { $item.ValueName }
        
        if ($choice -eq '2') {
            Set-ItemProperty -Path "Registry::$($item.Key)" -Name $vName -Value 0 -Force -ErrorAction SilentlyContinue
            Write-Host "[SUCCESS] Forced value to 0 on $($item.ValueName)." -ForegroundColor Green
        } elseif ($choice -eq '3') {
            Remove-ItemProperty -Path "Registry::$($item.Key)" -Name $vName -Force -ErrorAction SilentlyContinue
            Write-Host "[SUCCESS] Deleted $($item.ValueName) value data." -ForegroundColor Green
        } else {
            Write-Host "[INFO] Allowed $($item.ValueName)." -ForegroundColor Cyan
        }
    }
}

if (-not $changesFound) {
    Write-Host '[SUCCESS] Clear. No telemetry alterations or tracking keys detected.' -ForegroundColor Green
    Write-Host '================================================================' -ForegroundColor Yellow
    return
}

Write-Host ''
$updateBase = Read-Host 'Would you like to update your baseline to match current settings? (Y/N)'
if ($updateBase -ieq 'Y') {
    $currentScan | Export-Csv -Path $baselineFile -NoTypeInformation
    Write-Host '[SUCCESS] Baseline file updated.' -ForegroundColor Green
}
Write-Host '================================================================' -ForegroundColor Yellow
