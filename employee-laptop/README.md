# Employee laptop scripts

Two PowerShell scripts that set up and then keep current a Windows 11 Pro developer laptop
with the software in `../SOFTWARE_LIST_curated.md`. Both work in the Windows PowerShell 5.1
that ships with Windows, need no other files, and write an HTML report on the Desktop when
they finish.

| Script | What it does | Report |
|---|---|---|
| `setup-employee.ps1` | Fresh install: winget apps, Maven, JDK 25 + `JAVA_HOME`, Python 3.11, VS Code extensions, MSYS2 tools, WSL2 + Ubuntu 24.04, `.wslconfig`, manual checklist | `setup-employee-report.html`: every step PASS / FAIL / SKIP with an action for each failure |
| `update-employee.ps1` | Checks every installed tool for a newer version; with `-Install` applies the updates | `update-employee-report.html`: every tool UP-TO-DATE / AVAILABLE / UPDATED / FAILED with the install command |
| `update-employee.ps1 -Diff` | Compares the laptop with the standard toolset (missing / outdated / current), read-only | `laptop-diff-report.html` with **Start the upgrade** and **Install missing items** buttons |

## Before you start

- Sign in to Windows **as the account the employee will use every day**, not a vendor or
  setup account. Ubuntu, VS Code extensions, Python and `.wslconfig` are installed per user.
- Open **Windows PowerShell** with **Run as administrator**.
- The laptop needs internet access. If a proxy or security product blocks downloads, the
  report will say which items failed and where to get them by hand.

## 1. First-time setup

Copy `setup-employee.ps1` to the laptop (USB, email) or download it:

```powershell
irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/setup-employee.ps1 -OutFile setup-employee.ps1
```

Then run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1
```

1. The first run enables the Windows features for WSL2 and installs everything else.
   It ends with **REBOOT NOW** if a feature was enabled.
2. Reboot, open an Administrator PowerShell again and run the same command a second time.
   This installs Ubuntu 24.04. Already-installed items are skipped, so reruns are safe.
3. Open the report it saved on the Desktop. Fix anything listed under **Failed steps**
   using the action text, then work through the **Manual checklist** (Norton, Zscaler,
   Microsoft 365 sign-in, Surfshark, BitLocker, Docker first launch, Ubuntu first launch,
   git identity, CLI sign-ins, Windows Update).

Useful switches:

```powershell
.\setup-employee.ps1 -DryRun              # print what would run, write the report, change nothing
.\setup-employee.ps1 -Only winget,vscode  # run just these steps
.\setup-employee.ps1 -Skip msys2          # run everything except these
.\setup-employee.ps1 -NoOpen              # do not open the report in the browser
```

Steps: `features, winget, maven, java, python, vscode, msys2, wsl, wslconfig, checklist`.

## 2. Keeping the laptop up to date

Run monthly, or whenever a tool asks for an update:

```powershell
irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/update-employee.ps1 -OutFile update-employee.ps1
powershell -ExecutionPolicy Bypass -File .\update-employee.ps1            # check only
powershell -ExecutionPolicy Bypass -File .\update-employee.ps1 -Install   # check and install
```

- **Check only** (no `-Install`) never changes anything. The report lists each tool as
  up to date or update available, with the exact `winget upgrade` / `choco upgrade` command.
- **`-Install`** upgrades only the tools that `setup-employee.ps1` installed. Anything else
  winget finds on the machine is listed under *Manual checks* and left alone.
- Things the script cannot do for you and puts in the report instead: Windows Update
  (Settings), Ubuntu `apt upgrade` (needs the Linux password), and Microsoft 365 / Docker
  Desktop / IntelliJ in-app updaters if winget has not caught up yet.

Areas: `winget, choco, vscode, wsl, msys2, windows`. Use `-Only` / `-Skip` as above.

## 3. Show the diff and start the upgrade from the report

```powershell
powershell -ExecutionPolicy Bypass -File .\update-employee.ps1 -Diff
```

No admin rights needed. It compares the laptop with the standard toolset: every winget app,
Maven, `JAVA_HOME`, Python 3.11, the 8 VS Code extensions, the 6 MSYS2 packages, Ubuntu 24.04
and `.wslconfig`. Each item is MISSING, OUTDATED or CURRENT, and the report opens with:

- **Start the upgrade**: runs `update-employee.ps1 -Install` for the outdated items.
- **Install missing items**: runs `setup-employee.ps1` (idempotent, only adds what is missing).

The buttons link to `Start-Upgrade.cmd` / `Start-Setup.cmd`, written next to the report.
A browser cannot run PowerShell from a link, so the `.cmd` opens an elevated PowerShell and
Windows shows the UAC prompt. If the browser refuses to open the file, double-click the
`.cmd` on the Desktop. When the script was fetched from the Gist rather than a folder, the
`.cmd` downloads the script again from the Gist before running it.

## What is installed

| Group | Tools |
|---|---|
| Security | 7-Zip, Surfshark (Norton 360, Zscaler and BitLocker are manual) |
| Editors | IntelliJ IDEA, VS Code (+ 8 extensions), Notepad++, DBeaver, Postman, WinMerge |
| Languages | Oracle JDK 25, Node.js 24 LTS, Python 3.11 (Install Manager) + uv, PowerShell 7, MSYS2 (gcc, make, autotools, pkgconf) |
| Build / VCS | Apache Maven 3.9 (Chocolatey), Git + Git LFS, GitHub CLI |
| Containers / cloud | Docker Desktop, WSL2 + Ubuntu 24.04, AWS CLI v2, Terraform |
| AI tools | Claude desktop, Claude Code, GitHub Copilot CLI, OpenAI Codex CLI |
| Utilities | jq, FFmpeg |
| Office | Microsoft 365 Apps (Word, Excel, Outlook, OneNote), Teams, Zoom, WhatsApp (Store), Acrobat Reader |

VS Code extensions: `anthropic.claude-code`, `github.copilot`, `github.copilot-chat`,
`ms-python.python`, `vscjava.vscode-java-pack`, `ms-azuretools.vscode-containers`,
`eamodio.gitlens`, `ms-vscode.powershell`.

`.wslconfig` caps WSL2 at 6 GB RAM, 4 CPUs and 2 GB swap so Docker leaves room for
IntelliJ on a 16 GB laptop. Delete the file if the laptop has 32 GB.

## Maintaining these scripts

- The package list lives in `$WingetIds` at the top of **both** scripts; keep them identical.
- After editing, run `.\setup-employee.ps1 -DryRun -NoOpen` and `.\update-employee.ps1 -NoOpen`
  to check they still run, then push to the Gist:

  ```powershell
  gh gist edit 5ee0da6bf8c918f0ff94af6d58199040 -f setup-employee.ps1 setup-employee.ps1
  gh gist edit 5ee0da6bf8c918f0ff94af6d58199040 -f update-employee.ps1 update-employee.ps1
  ```

- The Gist is **public**. Keep company names, account details and local paths out of the scripts.
