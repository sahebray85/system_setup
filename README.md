# system_setup

Inventory and setup records for the development workstation used for Sharanaya Boutique projects.

- `INVENTORY.md` — categorized list of installed IDEs, languages, tools, security and productivity software.
- `NOTES.md` — unmanaged installs, duplicates and stale PATH entries to fix or codify later.
- `exports/` — machine-readable package lists (winget, Chocolatey, npm, pip, uv, VS Code, Antigravity, MSYS2, WSL).
- `bootstrap.ps1` — reinstalls everything in `exports/` on a fresh machine.

## Rebuilding a machine

Open PowerShell **as Administrator** (needed for Chocolatey and WSL), then:

```powershell
git clone <this repo> system_setup
cd system_setup
Set-ExecutionPolicy Bypass -Scope Process -Force
.\bootstrap.ps1 -DryRun          # preview every command
.\bootstrap.ps1                  # run all steps
.\bootstrap.ps1 -Only winget,npm # or a subset
.\bootstrap.ps1 -Skip wsl,msys2
```

Steps: `winget`, `choco`, `unmanaged`, `npm`, `python`, `uv`, `vscode`, `antigravity`, `msys2`, `wsl`.
Every step is idempotent, so the script can be rerun after a reboot or a partial failure.
Antigravity extensions are printed for manual install because Antigravity ships no extension CLI.

## Refreshing the exports

Rerun the collection commands listed at the top of `INVENTORY.md`, or simply:

```powershell
winget export -o exports/winget-full.json   # then filter to the dev IDs
choco export exports/choco-packages.config --include-version-numbers
npm ls -g --depth=0
pip freeze > exports/pip-3.11.txt
uv tool list --color never > exports/uv-tools.txt
code --list-extensions --show-versions > exports/vscode-extensions.txt
```
