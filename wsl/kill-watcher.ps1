param([Parameter(Mandatory=$true)][string]$CommandLinePattern)
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | ForEach-Object {
  if ($_.CommandLine -match $CommandLinePattern) {
    Stop-Process -Id $_.ProcessId -Force
    Write-Output "killed watcher PID $($_.ProcessId)"
  }
}
