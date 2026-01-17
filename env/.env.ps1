$EnvVars = @{
  "DOTFILES" = (Join-Path $env:USERPROFILE "dotfiles")
  "DEV_HOME" = (Join-Path $env:USERPROFILE "Dev")
  "EDITOR"   = "nano"
}

$PathAdd = @(
  (Join-Path $env:USERPROFILE "bin")
)
