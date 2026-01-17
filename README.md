## Windows (PowerShell)  Quick Start

### Install Git (if needed)
```powershell
winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
```

### Clone dotfiles (clone repo root, not /windows)
```powershell
git clone https://github.com/VladSart/dotfiles "C:\src\dotfiles"
# or
git clone https://github.com/VladSart/dotfiles "$env:USERPROFILE\dotfiles"
# or
git clone https://github.com/VladSart/dotfiles "D:\dotfiles"
```

### Run bootstrap (writes the $PROFILE hook)
```powershell
powershell -ExecutionPolicy Bypass -File "C:\src\dotfiles\windows\pwsh\bootstrap.ps1"
# adjust the path if you cloned elsewhere
```

### Verify / load now
```powershell
. $PROFILE
Reload
Current
```

## Daily commands

### Reload env + commands
```powershell
Reload
```

### Tooling status (installed only)
```powershell
Current
```

### Tooling status (including missing)
```powershell
Current -All
```

### Add a dotfiles-managed env var (writes to repo + reloads)
```powershell
AddVar "MY_VAR_NAME" "my value here"
```

### Force add/commit/push dotfiles changes (default message: "Force Field Push")
```powershell
Git-FFPush
```

### Notes
- bootstrap adds ONE line to $PROFILE that loads: windows\pwsh\profile.ps1 -> windows\env\Load-Env.ps1
- repo can live anywhere (C:, D:, etc); bootstrap wires the correct path
- if Git-FFPush fails on a new machine, you need GitHub auth (SSH key or HTTPS creds)

