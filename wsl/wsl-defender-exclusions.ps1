param([Parameter(Mandatory=$true)][string[]]$Paths)
# Defender exclusions for WSL2 + Docker build trees.
# Run elevated. Adds only; does not disable real-time protection.

$procs = @(
    'wsl.exe',
    'wslservice.exe',
    'wslhost.exe',
    'vmmemWSL',
    'docker.exe',
    'dockerd.exe'
)

foreach ($p in $Paths) {
    try { Add-MpPreference -ExclusionPath $p -ErrorAction Stop; Write-Host "path  + $p" }
    catch { Write-Host "path  ! $p  -> $($_.Exception.Message)" }
}

foreach ($p in $procs) {
    try { Add-MpPreference -ExclusionProcess $p -ErrorAction Stop; Write-Host "proc  + $p" }
    catch { Write-Host "proc  ! $p  -> $($_.Exception.Message)" }
}

Write-Host ""
Write-Host "=== current exclusions ==="
$pref = Get-MpPreference
Write-Host "Paths:"
$pref.ExclusionPath   | ForEach-Object { Write-Host "  $_" }
Write-Host "Processes:"
$pref.ExclusionProcess | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Done. Press Enter to close."
Read-Host
