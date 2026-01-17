$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)  # -> ...\dotfiles\windows
$Loader = Join-Path $DotfilesRoot "env\Load-Env.ps1"                                  # -> ...\dotfiles\windows\env\Load-Env.ps1

if (Test-Path $Loader) {
  . $Loader -Scope User
} else {
  Write-Host "Missing loader: $Loader" -ForegroundColor Yellow
}
