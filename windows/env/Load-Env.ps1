param(
  [ValidateSet("Process","User","Machine")]
  [string]$Scope = "User",
  [string]$EnvFile = "$PSScriptRoot\.env.ps1",
  [string]$LocalEnvFile = "$PSScriptRoot\.env.local.ps1"
)

$script:DotfilesRoot = Split-Path $PSScriptRoot -Parent

function Set-OneEnvVar {
  param([string]$Name,[string]$Value,[string]$Scope)
  if ([string]::IsNullOrWhiteSpace($Name)) { return }
  [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
  Set-Item -Path "Env:$Name" -Value $Value
}

function Add-ToPath {
  param([string]$PathToAdd,[string]$Scope)
  if ([string]::IsNullOrWhiteSpace($PathToAdd)) { return }
  if (-not (Test-Path $PathToAdd)) { return }

  $current = [Environment]::GetEnvironmentVariable("Path", $Scope)
  $parts = @()
  if ($current) { $parts = $current -split ';' | Where-Object { $_ -and $_.Trim() } }
  if ($parts -contains $PathToAdd) { return }

  $new = ($parts + $PathToAdd) -join ';'
  [Environment]::SetEnvironmentVariable("Path", $new, $Scope)
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
}

function Import-EnvDefinition {
  param([string]$File,[string]$Scope)
  if (-not (Test-Path $File)) { return @{ Vars=0; Paths=0 } }

  $script:EnvVars = $null
  $script:PathAdd = $null
  . $File

  $varsCount = 0
  $pathCount = 0

  if ($EnvVars) {
    foreach ($k in $EnvVars.Keys) {
      Set-OneEnvVar -Name $k -Value $EnvVars[$k] -Scope $Scope
      $varsCount++
    }
  }

  if ($PathAdd) {
    foreach ($p in $PathAdd) {
      Add-ToPath -PathToAdd $p -Scope $Scope
      $pathCount++
    }
  }

  @{ Vars=$varsCount; Paths=$pathCount }
}

function Show-DotfilesBanner {
  param([int]$VarsLoaded,[int]$PathsAdded,[string]$Scope)
  $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host ""
  Write-Host " __      __ _           _ " -ForegroundColor Cyan
  Write-Host " \ \    / /| |         | |" -ForegroundColor Cyan
  Write-Host "  \ \  / /_| | __ _  __| |" -ForegroundColor Cyan
  Write-Host "   \ \/ / _` |/ _` |/ _` |" -ForegroundColor Cyan
  Write-Host "    \  / (_| | (_| | (_| |" -ForegroundColor Cyan
  Write-Host "     \/ \__,_|\__,_|\__,_|" -ForegroundColor Cyan
  Write-Host "  dotfiles env loaded | scope=$Scope | $t" -ForegroundColor Green
  Write-Host ""
}

function Invoke-DotfilesEnvLoad {
  param(
    [ValidateSet("Process","User","Machine")]
    [string]$Scope = "User",
    [switch]$NoBanner
  )
  $a = Import-EnvDefinition -File $EnvFile -Scope $Scope
  $b = Import-EnvDefinition -File $LocalEnvFile -Scope $Scope
  if (-not $NoBanner) { Show-DotfilesBanner -VarsLoaded ($a.Vars+$b.Vars) -PathsAdded ($a.Paths+$b.Paths) -Scope $Scope }
}

function Reload {
  param([switch]$Pull,[ValidateSet("Process","User","Machine")][string]$Scope="User")
  if ($Pull -and (Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path (Join-Path $script:DotfilesRoot ".git"))) {
    git -C $script:DotfilesRoot pull | Out-Null
  }
  Invoke-DotfilesEnvLoad -Scope $Scope
}

Invoke-DotfilesEnvLoad -Scope $Scope


function Add-EnvVar {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Value,
    [ValidateSet("User","Machine","Process")][string]$Scope="User"
  )

  $envFile = Join-Path $PSScriptRoot ".env.ps1"
  if (-not (Test-Path $envFile)) { throw "Missing $envFile" }

  $defs = & {
    $EnvVars = @{}
    $PathAdd = @()
    . $envFile
    [pscustomobject]@{ EnvVars = $EnvVars; PathAdd = $PathAdd }
  }

  if (-not $defs.EnvVars) { $defs.EnvVars = @{} }
  $defs.EnvVars[$Name] = $Value

  $out = New-Object System.Collections.Generic.List[string]
  $out.Add('$EnvVars = @{')
  foreach ($k in ($defs.EnvVars.Keys | Sort-Object)) {
    $v = [string]$defs.EnvVars[$k]
    $v = $v.Replace('"','`"')
    $out.Add("  `"$k`" = `"$v`"")
  }
  $out.Add('}')
  $out.Add('')
  $out.Add('$PathAdd = @(')
  foreach ($p in ($defs.PathAdd | ForEach-Object {[string]$_})) {
    $pv = $p.Replace('"','`"')
    $out.Add("  `"$pv`"")
  }
  $out.Add(')')

  Set-Content -Encoding UTF8 -Path $envFile -Value ($out -join "`r`n")

  Reload -Scope $Scope
  Write-Host "Added/updated $Name and reloaded." -ForegroundColor Green
}

function Push-Dotfiles {
  param([string]$Message = "Update dotfiles")
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git not found" }

  $root = $script:DotfilesRoot
  if (-not (Test-Path (Join-Path $root ".git"))) { throw "Not a git repo: $root" }

  git -C $root add env\.env.ps1 env\Load-Env.ps1 .gitignore | Out-Null

  $dirty = git -C $root status --porcelain
  if (-not $dirty) {
    Write-Host "Nothing to commit." -ForegroundColor Yellow
    return
  }

  git -C $root commit -m $Message | Out-Null
  git -C $root push | Out-Null
  Write-Host "Pushed to GitHub." -ForegroundColor Green
}


function AddVar {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Value,
    [ValidateSet("User","Machine","Process")][string]$Scope="User"
  )

  $envFile = Join-Path $PSScriptRoot ".env.ps1"
  if (-not (Test-Path $envFile)) { throw "Missing $envFile" }

  $defs = & {
    $EnvVars = @{}
    $PathAdd = @()
    . $envFile
    [pscustomobject]@{ EnvVars = $EnvVars; PathAdd = $PathAdd }
  }

  if (-not $defs.EnvVars) { $defs.EnvVars = @{} }
  $defs.EnvVars[$Name] = $Value

  $out = New-Object System.Collections.Generic.List[string]
  $out.Add('$EnvVars = @{')
  foreach ($k in ($defs.EnvVars.Keys | Sort-Object)) {
    $v = [string]$defs.EnvVars[$k]
    $v = $v.Replace('"','`"')
    $out.Add("  `"$k`" = `"$v`"")
  }
  $out.Add('}')
  $out.Add('')
  $out.Add('$PathAdd = @(')
  foreach ($p in ($defs.PathAdd | ForEach-Object {[string]$_})) {
    $pv = $p.Replace('"','`"')
    $out.Add("  `"$pv`"")
  }
  $out.Add(')')

  Set-Content -Encoding UTF8 -Path $envFile -Value ($out -join "`r`n")
  Reload -Scope $Scope
  Write-Host "Added/updated $Name in .env.ps1 and reloaded." -ForegroundColor Green
}

function Current {
  $envFile = Join-Path $PSScriptRoot ".env.ps1"
  if (-not (Test-Path $envFile)) { throw "Missing $envFile" }

  $defs = & {
    $EnvVars = @{}
    $PathAdd = @()
    . $envFile
    [pscustomobject]@{ EnvVars = $EnvVars; PathAdd = $PathAdd }
  }

  $defs.EnvVars.GetEnumerator() |
    Sort-Object Name |
    Format-Table -AutoSize Name, Value
}


function Managed {
  $envFile = Join-Path $PSScriptRoot ".env.ps1"
  if (-not (Test-Path $envFile)) { throw "Missing $envFile" }

  $defs = & {
    $EnvVars = @{}
    $PathAdd = @()
    . $envFile
    [pscustomobject]@{ EnvVars = $EnvVars; PathAdd = $PathAdd }
  }

  $defs.EnvVars.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object {
      [pscustomobject]@{
        Name = $_.Name
        DefinedValue = $_.Value
        CurrentValue = (Get-Item "Env:$($_.Name)" -ErrorAction SilentlyContinue).Value
      }
    } | Format-Table -AutoSize
}

function Current {
  Get-ChildItem Env: |
    Sort-Object Name |
    Format-Table -AutoSize Name, Value
}


function Get-CmdInfo {
  param([Parameter(Mandatory=$true)][string]$Name, [string[]]$Args=@("--version"))
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) {
    return [pscustomobject]@{ Tool=$Name; Installed=$false; Version=""; Path="" }
  }

  $ver = ""
  try {
    $ver = (& $cmd.Source @Args 2>$null | Select-Object -First 1)
    if (-not $ver) { $ver = (& $Name @Args 2>$null | Select-Object -First 1) }
  } catch {}

  [pscustomobject]@{
    Tool      = $Name
    Installed = $true
    Version   = [string]$ver
    Path      = $cmd.Source
  }
}

function Current {
  $items = @()

  $items += Get-CmdInfo git @("--version")
  $items += Get-CmdInfo winget @("--version")
  $items += Get-CmdInfo choco @("--version")
  $items += Get-CmdInfo scoop @("--version")

  $items += Get-CmdInfo pwsh @("--version")
  $items += Get-CmdInfo python @("--version")
  $items += Get-CmdInfo py @("--version")
  $items += Get-CmdInfo node @("--version")
  $items += Get-CmdInfo npm @("--version")
  $items += Get-CmdInfo yarn @("--version")
  $items += Get-CmdInfo pnpm @("--version")
  $items += Get-CmdInfo go @("version")
  $items += Get-CmdInfo java @("-version")
  $items += Get-CmdInfo dotnet @("--info")

  $items += Get-CmdInfo docker @("--version")
  $items += Get-CmdInfo kubectl @("version","--client","--output=yaml")
  $items += Get-CmdInfo helm @("version","--short")
  $items += Get-CmdInfo terraform @("version")
  $items += Get-CmdInfo packer @("version")

  $items += Get-CmdInfo az @("version")
  $items += Get-CmdInfo aws @("--version")
  $items += Get-CmdInfo gcloud @("--version")

  $items += Get-CmdInfo code @("--version")
  $items += Get-CmdInfo vim @("--version")
  $items += Get-CmdInfo nano @("--version")

  $items |
    ForEach-Object {
      [pscustomobject]@{
        Tool      = $_.Tool
        Installed = $_.Installed
        Version   = ($_.Version -replace "\s+"," " -replace "`r|`n","") 
        Path      = $_.Path
      }
    } |
    Sort-Object -Property @{Expression='Installed';Descending=$true}, Tool |
    Format-Table -AutoSize Tool, Installed, Version, Path
}

function EnvAll {
  Get-ChildItem Env: | Sort-Object Name | Format-Table -AutoSize Name, Value
}



# --- Override Current with a cleaner version (supports -All) ---
function Current {
  param([switch]$All)

  $tools = @(
    @{n="git";      a=@("--version")}
    @{n="winget";   a=@("--version")}
    @{n="choco";    a=@("--version")}
    @{n="scoop";    a=@("--version")}

    @{n="pwsh";     a=@("--version")}
    @{n="python";   a=@("--version")}
    @{n="py";       a=@("--version")}
    @{n="node";     a=@("--version")}
    @{n="npm";      a=@("--version")}
    @{n="yarn";     a=@("--version")}
    @{n="pnpm";     a=@("--version")}
    @{n="go";       a=@("version")}
    @{n="java";     a=@("-version")}
    @{n="dotnet";   a=@("--info")}

    @{n="docker";   a=@("--version")}
    @{n="kubectl";  a=@("version","--client")}
    @{n="helm";     a=@("version","--short")}
    @{n="terraform";a=@("version")}
    @{n="packer";   a=@("version")}

    @{n="az";       a=@("version")}
    @{n="aws";      a=@("--version")}
    @{n="gcloud";   a=@("--version")}

    @{n="code";     a=@("--version")}
    @{n="vim";      a=@("--version")}
    @{n="nano";     a=@("--version")}
  )

  $items = foreach ($t in $tools) {
    $name = $t.n
    $cmd = Get-Command $name -ErrorAction SilentlyContinue

    if (-not $cmd) {
      [pscustomobject]@{ Tool=$name; Installed=$false; Version=""; Path="" }
      continue
    }

    $ver = ""
    try { $ver = (& $cmd.Source @($t.a) 2>$null | Select-Object -First 1) } catch {}
    $ver = [string]$ver
    $ver = ($ver -replace "`r|`n","") -replace "\s+"," "

    [pscustomobject]@{ Tool=$name; Installed=$true; Version=$ver; Path=$cmd.Source }
  }

  if (-not $All) { $items = $items | Where-Object Installed }

  $items | Sort-Object Tool | Format-Table -AutoSize Tool, Installed, Version, Path
}
# --- end override ---

