param(
    [Parameter(Mandatory=$true)][string]$VhdPath,
    [Parameter(Mandatory=$true)][int]$PagefileInitialMB,
    [Parameter(Mandatory=$true)][int]$PagefileMaximumMB,
    [switch]$Apply,
    [string]$LogPath = (Join-Path $env:TEMP 'fix-disk.log')
)
if (-not $Apply) { throw 'Use -Apply to delete CBS logs, disable hibernation, change the pagefile and compact the supplied VHD.' }
$ErrorActionPreference = 'Continue'
$log = $LogPath
function Say($m) { $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $m; Write-Host $line; Add-Content -LiteralPath $log -Value $line -Encoding utf8 }
function FreeGB { [math]::Round((Get-PSDrive C).Free/1GB, 2) }

Set-Content -LiteralPath $log -Value '' -Encoding utf8

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ''
    Write-Host '  NOT ELEVATED. Nothing was changed.' -ForegroundColor Red
    Write-Host '  Open an admin terminal (Win+X, then "Terminal (Admin)") and run:' -ForegroundColor Yellow
    Write-Host "      powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -VhdPath <path> -PagefileInitialMB <MB> -PagefileMaximumMB <MB> -Apply" -ForegroundColor Yellow
    Write-Host ''
    Read-Host 'Press Enter to close'
    exit 1
}

Say "START (elevated). Free = $(FreeGB) GB"

# --- 0. Make sure WSL is fully down so the vhdx is unlocked ---
Say "Shutting down WSL..."
& wsl.exe --shutdown
Start-Sleep -Seconds 5

# --- 1. Windows servicing logs (pure logs, regenerate on their own) ---
$cbsFreed = 0
Get-ChildItem 'C:\Windows\Logs\CBS' -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $sz = $PSItem.Length
    try { Remove-Item -LiteralPath $PSItem.FullName -Force -ErrorAction Stop; $cbsFreed += $sz }
    catch { Say "  skip (in use): $($PSItem.Name)" }
}
Say "CBS logs removed: $([math]::Round($cbsFreed/1GB,2)) GB. Free = $(FreeGB) GB"

# --- 2. Hibernation file (disables hibernate + fast startup) ---
Say "Disabling hibernation..."
& powercfg.exe /h off
Start-Sleep -Seconds 2
$hib = Get-ChildItem 'C:\' -Force -ErrorAction SilentlyContinue | Where-Object { $PSItem.Name -eq 'hiberfil.sys' }
if ($hib) { Say "  hiberfil.sys STILL PRESENT ($([math]::Round($hib.Length/1GB,2)) GB)" } else { Say "  hiberfil.sys removed" }
Say "Free = $(FreeGB) GB"

# Apply the requested pagefile sizes.
Say "Setting pagefile size..."
try {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop
        Say "  automatic management disabled"
    }
    $pf = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue
    if ($null -eq $pf) {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = 'C:\pagefile.sys'; InitialSize = $PagefileInitialMB; MaximumSize = $PagefileMaximumMB } -ErrorAction Stop | Out-Null
        Say "  created fixed setting $PagefileInitialMB/$PagefileMaximumMB MB"
    } else {
        Set-CimInstance -InputObject $pf -Property @{ InitialSize = $PagefileInitialMB; MaximumSize = $PagefileMaximumMB } -ErrorAction Stop
        Say "  set existing to $PagefileInitialMB/$PagefileMaximumMB MB"
    }
    $v = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue
    Say "  verify: InitialSize=$($v.InitialSize) MaximumSize=$($v.MaximumSize)"
    Say "  NOTE: pagefile.sys changes take effect AFTER A REBOOT"
} catch { Say "  PAGEFILE FAILED: $($PSItem.Exception.Message)" }

# Compact the supplied WSL disk.
$vhd = $VhdPath
if (Test-Path -LiteralPath $vhd) {
    $before = (Get-Item -LiteralPath $vhd).Length
    Say "Compacting ext4.vhdx ($([math]::Round($before/1GB,2)) GB). This can take 10-30 min, be patient..."
    $dp = Join-Path $env:TEMP 'compact-wsl.txt'
    @(
        "select vdisk file=`"$vhd`""
        "attach vdisk readonly"
        "compact vdisk"
        "detach vdisk"
        "exit"
    ) | Set-Content -LiteralPath $dp -Encoding ascii
    $out = & diskpart.exe /s $dp 2>&1 | Out-String
    Add-Content -LiteralPath $log -Value $out -Encoding utf8
    Write-Host $out
    $after = (Get-Item -LiteralPath $vhd).Length
    Say "ext4.vhdx now $([math]::Round($after/1GB,2)) GB (reclaimed $([math]::Round(($before-$after)/1GB,2)) GB)"
    Remove-Item -LiteralPath $dp -Force -ErrorAction SilentlyContinue
} else { Say "vhdx NOT FOUND at $vhd" }

Say "DONE. Free = $(FreeGB) GB"
Say "=> REBOOT to apply pagefile changes."
Add-Content -LiteralPath $log -Value '===COMPLETE===' -Encoding utf8
Write-Host ''
Read-Host 'Press Enter to close'
