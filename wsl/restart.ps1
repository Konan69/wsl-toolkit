param(
  [Parameter(Mandatory=$true)][string]$Distro,
  [Parameter(Mandatory=$true)][string]$AppPath,
  [Parameter(Mandatory=$true)][string]$ProcessName,
  [string]$LogPath = (Join-Path $env:TEMP 'restart.log')
)
$log = $LogPath
"start $(Get-Date)" | Out-File $log -Encoding utf8
Start-Sleep -Seconds 25
wsl.exe -d $Distro -e true
Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 6
Start-Process $AppPath
"relaunched $(Get-Date)" | Out-File $log -Append -Encoding utf8
