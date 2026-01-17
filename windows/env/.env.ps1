$EnvVars = @{
  "DOTFILES" = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))  # -> repo root
  "DEV_HOME" = (Join-Path $env:USERPROFILE "Dev")
}
$PathAdd = @(
  (Join-Path $env:USERPROFILE "bin")
)
