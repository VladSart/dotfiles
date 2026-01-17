$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Loader = Join-Path $DotfilesRoot "windows\env\Load-Env.ps1"
if (Test-Path $Loader) { . $Loader -Scope User } else { Write-Host "Missing loader: $Loader" -ForegroundColor Yellow }
