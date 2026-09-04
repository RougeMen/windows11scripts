try {
    # --- Verify Administrator Elevation Natively ---
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[!] Requires Administrator elevation. Relaunching..." -ForegroundColor Yellow
        $m = [System.IO.File]::ReadAllText($MyInvocation.MyCommand.Path)
        Start-Process powershell -ArgumentList "-NoProfile -NoExit -Command `"$m`"" -Verb RunAs
        exit
    }
    Write-Host "=== Starting Total Repository Provisioning Natively ===" -ForegroundColor Cyan
    [System.Net.ServicePointManager]::SecurityProtocol = 3072
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $C = "https:" + "//" + "community.chocolatey.org" + "/" + "install.ps1"
    $S = "https:" + "//" + "get.scoop.sh"
    $V = "https:" + "//" + "github.com" + "/" + "microsoft" + "/" + "vcpkg.git"
    Write-Host "`n[1/8] Configuring WinGet sources..." -ForegroundColor Yellow
    winget source reset --force
    winget upgrade --all --accept-source-agreements --accept-package-agreements --silent *>`$null
    Write-Host "`n[2/8] Checking Chocolatey..." -ForegroundColor Yellow
    if (!(Get-Command choco -EA SilentlyContinue)) { iex ((New-Object System.Net.WebClient).DownloadString($C)) }
    Write-Host "`n[3/8] Checking Scoop..." -ForegroundColor Yellow
    if (!(Get-Command scoop -EA SilentlyContinue)) { `$env:SCOOP="C:\Scoop"; [Environment]::SetEnvironmentVariable("SCOOP", "C:\Scoop", "Machine"); iex (New-Object System.Net.WebClient).DownloadString($S) }
    Write-Host "`n[4/8] Installing Git..." -ForegroundColor Yellow
    winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements --silent
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "`n[5/8] Deploying vcpkg..." -ForegroundColor Yellow
    if (!(Test-Path "C:\vkvpkg_lock")) { if (Test-Path "C:\vcpkg") { Remove-Item "C:\vcpkg" -Recurse -Force -EA SilentlyContinue }; git clone --depth=1 $V C:\vcpkg; if (Test-Path "C:\vcpkg\bootstrap-vcpkg.bat") { cd C:\vcpkg; .\bootstrap-vcpkg.bat; New-Item -Path "C:\vkvpkg_lock" -ItemType File -Force *>`$null; cd ~ } }
    Write-Host "`n[6/8] Installing MSYS2..." -ForegroundColor Yellow
    winget install --id MSYS2.MSYS2 --exact --silent
    Write-Host "`n[7/8] Installing Python Environment..." -ForegroundColor Yellow
    winget install --id Anaconda.Miniconda3 --exact --silent
    winget install --id astral-sh.uv --exact --silent
    if (!(Get-Command pipx -EA SilentlyContinue)) { winget install --id Python.Pipx --exact --silent *>`$null }
    Write-Host "`n[8/8] Installing JS Runtimes..." -ForegroundColor Yellow
    winget install --id OpenJS.NodeJS --exact --silent
    winget install --id pnpm.pnpm --exact --silent
    winget install --id Oven.Bun --exact --silent *>`$null
    Write-Host "`n=== PROVISIONING SUCCESSFUL! ===" -ForegroundColor Green
} catch { Write-Host "`n[!] Critical Error: $_" -ForegroundColor Red }
finally { Read-Host "Press Enter to close this window" }
