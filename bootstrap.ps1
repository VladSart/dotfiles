$Repo = Join-Path $env:USERPROFILE "dotfiles"
$ProfileHook = '. (Join-Path $env:USERPROFILE "dotfiles\pwsh\profile.ps1")'

if (-not (Test-Path $Repo)) { throw "dotfiles repo not found at $Repo" }
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }

$raw = Get-Content $PROFILE -Raw
if ($raw -notmatch [regex]::Escape("dotfiles\pwsh\profile.ps1")) {
  Add-Content -Path $PROFILE -Value "`r`n$ProfileHook`r`n"
}

. (Join-Path $Repo "pwsh\profile.ps1")
Write-Host "Dotfiles installed. Open a new PowerShell or run: Reload" -ForegroundColor Green
