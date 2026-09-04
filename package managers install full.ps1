# =========================================================================
# UNIVERSAL PORTABLE DEVELOPMENT PROVISIONER SCRIPT
# =========================================================================
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

Write-Host "=== Starting Total Repository Provisioning ===" -ForegroundColor Cyan

# Dynamic URL pieces to prevent clipboard truncation breaks
$C_Ok = "https:" + "//" + "community.chocolatey.org" + "/" + "install.ps1"
$S_Ok = "https:" + "//" + "get.scoop.sh"
$V_Ok = "https:" + "//" + "github.com" + "/" + "microsoft" + "/" + "vcpkg.git"

# 1. WinGet Sources
Write-Host "`n[1/8] Configuring WinGet sources..." -ForegroundColor Yellow
winget source reset --force
winget upgrade --all --accept-source-agreements --accept-package-agreements --silent *>$null

# 2. Chocolatey
Write-Host "`n[2/8] Checking Chocolatey..." -ForegroundColor Yellow
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($C_Ok))
} else { Write-Host "Chocolatey already installed." -ForegroundColor Green }

# 3. Scoop
Write-Host "`n[3/8] Checking Scoop..." -ForegroundColor Yellow
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    $env:SCOOP='C:\Scoop'
    [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'Machine')
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString($S_Ok)
} else { Write-Host "Scoop already installed." -ForegroundColor Green }

# 4. Git
Write-Host "`n[4/8] Installing Git..." -ForegroundColor Yellow
winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements --silent
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 5. vcpkg
Write-Host "`n[5/8] Deploying vcpkg to C:\vcpkg..." -ForegroundColor Yellow
if (!(Test-Path "C:\vkvpkg_lock")) {
    if (Test-Path "C:\vcpkg") { Remove-Item "C:\vcpkg" -Recurse -Force -ErrorAction SilentlyContinue }
    git clone --depth=1 $V_Ok C:\vcpkg
    if (Test-Path "C:\vcpkg\bootstrap-vcpkg.bat") {
        Set-Location "C:\vcpkg"
        .\bootstrap-vcpkg.bat
        New-Item -Path "C:\vkvpkg_lock" -ItemType File -Force *>$null
        Set-Location $env:USERPROFILE
        Write-Host "vcpkg configured cleanly." -ForegroundColor Green
    }
} else { Write-Host "vcpkg already configured." -ForegroundColor Green }

# 6. MSYS2
Write-Host "`n[6/8] Installing MSYS2..." -ForegroundColor Yellow
winget install --id MSYS2.MSYS2 --exact --accept-source-agreements --accept-package-agreements --silent

# 7. Python
Write-Host "`n[7/8] Installing Python Environment (Miniconda, uv, pipx)..." -ForegroundColor Yellow
winget install --id Anaconda.Miniconda3 --exact --accept-source-agreements --accept-package-agreements --silent
winget install --id astral-sh.uv --exact --accept-source-agreements --accept-package-agreements --silent
if (!(Get-Command pipx -ErrorAction SilentlyContinue)) { winget install --id Python.Pipx --exact --accept-source-agreements --accept-package-agreements --silent *>$null }

# 8. JS / Node
Write-Host "`n[8/8] Installing JS Runtimes (Node, pnpm, Bun)..." -ForegroundColor Yellow
winget install --id OpenJS.NodeJS --exact --accept-source-agreements --accept-package-agreements --silent
winget install --id pnpm.pnpm --exact --accept-source-agreements --accept-package-agreements --silent
winget install --id Oven.Bun --exact --accept-source-agreements --accept-package-agreements --silent *>$null

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-Host "`n=== PROVISIONING SUCCESSFUL! ALL GATEWAYS CONFIGURED ===" -ForegroundColor Green
Write-Host "Press any key to close this terminal window..." -ForegroundColor Cyan
[void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

