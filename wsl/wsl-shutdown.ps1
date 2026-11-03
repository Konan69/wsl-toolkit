param(
  [string]$ClaudePath = 'claude.exe',
  [string]$LogPath = (Join-Path $env:TEMP 'wsl-shutdown.log')
)
Start-Sleep -Seconds 30
$log = $LogPath
"start $(Get-Date)" | Out-File $log
& $ClaudePath -p 'The user asked you to shut down WSL. Run exactly this one command: wsl --shutdown . Then run wsl --list --running and report the result.' --allowedTools 'Bash(wsl*)' 'PowerShell(wsl*)' --max-turns 5 *>> $log
"end $(Get-Date)" | Out-File $log -Append
