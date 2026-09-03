<#
.SYNOPSIS
    Windows 11 Deep Cleaner - PowerShell Edition
.DESCRIPTION
    A native PowerShell maintenance script to clear temporary files, 
    flush the DNS resolver cache, and empty the Recycle Bin.
#>

# Set Console Title
$Host.UI.RawUI.WindowTitle = "Windows 11 Deep Cleaner"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      Windows 11 Deep Cleaner           " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Clear User and System Temporary Files
Write-Host "[+] Clearing Windows Temporary Files..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "    Temporary files cleared." -ForegroundColor Green

# 2. Flush DNS Cache
Write-Host "[+] Flushing DNS Cache..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host "    DNS Cache flushed successfully." -ForegroundColor Green

# 3. Clear Recycle Bin
Write-Host "[+] Clearing Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "    Recycle Bin emptied." -ForegroundColor Green

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Optimization complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Pause execution before closing
Read-Host -Prompt "Press Enter to exit"
