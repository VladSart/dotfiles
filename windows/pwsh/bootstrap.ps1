$DotfilesRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfileScript = Join-Path $DotfilesRoot "profile.ps1"
if (-not (Test-Path $ProfileScript)) { throw "Missing $ProfileScript" }

$line = ". `"$ProfileScript`""

if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }

$raw = Get-Content $PROFILE -Raw
if ($raw -notmatch [regex]::Escape($ProfileScript)) {
  Add-Content -Path $PROFILE -Value "`r`n$line`r`n"
}

. $ProfileScript
Write-Host "Windows PowerShell profile wired. Open a new session or run: Reload" -ForegroundColor Green
