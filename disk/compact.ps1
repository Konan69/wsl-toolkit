param(
  [Parameter(Mandatory=$true)][string]$VhdPath,
  [string]$LogPath = (Join-Path $env:TEMP 'compact.log')
)
$ErrorActionPreference = 'Continue'
$log = $LogPath
$vhd = $VhdPath
"=== start $(Get-Date)" | Out-File $log -Encoding utf8
"before: {0:N1} GB" -f ((Get-Item $vhd).Length/1GB) | Out-File $log -Append -Encoding utf8
wsl.exe --shutdown
Start-Sleep -Seconds 8
$dp = "$env:TEMP\wsl-compact.txt"
@"
select vdisk file="$vhd"
attach vdisk readonly
compact vdisk
detach vdisk
"@ | Out-File $dp -Encoding ascii
diskpart /s $dp 2>&1 | Out-File $log -Append -Encoding utf8
"after: {0:N1} GB" -f ((Get-Item $vhd).Length/1GB) | Out-File $log -Append -Encoding utf8
"C free: {0:N1} GB" -f ((Get-PSDrive C).Free/1GB) | Out-File $log -Append -Encoding utf8
"=== done $(Get-Date)" | Out-File $log -Append -Encoding utf8
