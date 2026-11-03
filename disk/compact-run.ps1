param(
  [Parameter(Mandatory=$true)][string]$VhdPath,
  [Parameter(Mandatory=$true)][string]$DiskpartScript,
  [Parameter(Mandatory=$true)][string]$Distro,
  [string]$LogPath = (Join-Path $env:TEMP 'compact-run.log')
)
$ErrorActionPreference = 'Continue'
$log = $LogPath
"=== started $(Get-Date -Format o) ===" | Out-File -Encoding utf8 $log

$v = $VhdPath

"BEFORE VHDX: $([math]::Round((Get-Item $v).Length/1GB,2)) GiB" | Tee-Object -FilePath $log -Append

"--- wsl --shutdown ---" | Tee-Object -FilePath $log -Append
wsl.exe --shutdown 2>&1 | Tee-Object -FilePath $log -Append
Start-Sleep -Seconds 5

"--- dismount disk image if still attached ---" | Tee-Object -FilePath $log -Append
try {
  $img = Get-DiskImage -ImagePath $v -ErrorAction Stop
  if ($img.Attached) {
    Dismount-DiskImage -ImagePath $v -ErrorAction Stop | Out-Null
    "dismounted" | Tee-Object -FilePath $log -Append
  } else {
    "not attached" | Tee-Object -FilePath $log -Append
  }
} catch {
  "dismount step: $($_.Exception.Message)" | Tee-Object -FilePath $log -Append
}

"--- wsl --manage $Distro --set-sparse true ---" | Tee-Object -FilePath $log -Append
wsl.exe --manage $Distro --set-sparse true 2>&1 | Tee-Object -FilePath $log -Append

"--- wsl --shutdown again before compact ---" | Tee-Object -FilePath $log -Append
wsl.exe --shutdown 2>&1 | Tee-Object -FilePath $log -Append
Start-Sleep -Seconds 5

"--- diskpart compact (this is the slow step, no progress bar) ---" | Tee-Object -FilePath $log -Append
diskpart /s $DiskpartScript 2>&1 | Tee-Object -FilePath $log -Append

"AFTER  VHDX: $([math]::Round((Get-Item $v).Length/1GB,2)) GiB" | Tee-Object -FilePath $log -Append
"C: free: $([math]::Round((Get-PSDrive C).Free/1GB,2)) GiB" | Tee-Object -FilePath $log -Append
"=== finished $(Get-Date -Format o) ===" | Tee-Object -FilePath $log -Append
