# Workstation Software Inventory

Machine: HP laptop, Windows 11 Pro 10.0.26200, user `saheb`. Snapshot taken 2026-09-18.

Gathered read-only from `winget list`, `choco list`, `npm ls -g`, `pip list`, `uv tool list`,
`code --list-extensions`, `vswhere`, MSYS2 `pacman -Qe`, `wsl --list`, `apt-mark showmanual`
inside Ubuntu, Windows Security Center (`root/SecurityCenter2`), service and adapter listings,
PATH inspection, and `--version` probes of about 100 common developer commands.

Machine-readable copies of the package lists live in [`exports/`](exports/). Duplicates, stale
entries and follow-ups are in [`NOTES.md`](NOTES.md).

## 1. IDEs and editors

| Tool | Version | Source / location |
|---|---|---|
| IntelliJ IDEA (Ultimate line) | 2026.1.3 | winget `JetBrains.IntelliJIDEA`, `C:\Program Files\JetBrains\IntelliJ IDEA 2026.1.3` |
| Visual Studio Code (User) | 1.138.0 (CLI reports 1.137.0) | winget `Microsoft.VisualStudioCode`, `%LOCALAPPDATA%\Programs\Microsoft VS Code` |
| Visual Studio Code (Store/MSIX) | 1.0.138.0 | MSIX duplicate of the above |
| Antigravity (Google AI IDE) | 2.0.6 | winget `Google.Antigravity`, `%LOCALAPPDATA%\Programs\Antigravity` |
| Visual Studio Build Tools 2019 | 16.11.35706 | choco `visualstudio2019buildtools` + `visualstudio2019-workload-vctools`; `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools` |
| Notepad++ | 8.8.8 | winget `Notepad++.Notepad++` (plus an MSIX duplicate) |
| DBeaver Community | 26.1.0 | winget `DBeaver.DBeaver.Community` |
| Postman | 12.28.6 | user install (ARP) |
| Windows Terminal | 1.24.11911 | winget `Microsoft.WindowsTerminal` |
| WinMerge | 2.16.58.2 | installer (plus an MSIX duplicate) |

## 2. Languages and runtimes

### Java (six installs)

| Location | Version | Notes |
|---|---|---|
| `C:\Java25` | Oracle JDK 25.0.3 LTS | `JAVA_HOME`; on machine PATH; what `javapath` resolves to |
| `C:\Java21` | OpenJDK 21.0.9 LTS | hand-extracted |
| `C:\Java17` | OpenJDK 17.0.14 LTS | hand-extracted |
| `C:\Java` | OpenJDK 23.0.1 | unlabeled directory, hand-extracted |
| `C:\Program Files\Java\latest\jdk-25` | Oracle JDK 25 | installer (ARP "Java(TM) SE Development Kit 25.0.3") |
| `%USERPROFILE%\.jdks\ms-21.0.11` | Microsoft OpenJDK 21.0.11 | downloaded by IntelliJ |

### Others

| Runtime | Version | Location |
|---|---|---|
| Node.js | 24.12.0 (npm 11.6.2) | `C:\Program Files\nodejs` (MSI) |
| Python | 3.11.9 | Python Install Manager 26.3 (`pymanager`), `%LOCALAPPDATA%\Python\pythoncore-3.11-64`; pip 26.1.2 |
| uv | 0.11.28 | `%USERPROFILE%\.local\bin` |
| .NET | Runtime 7.0.9 + WindowsDesktop 7.0.9 + ASP.NET Core 7.0.9 (x86) | `C:\Program Files\dotnet`; **no SDK installed** |
| PowerShell | 7.6.6 | winget `Microsoft.PowerShell` |
| GCC (MSYS2) | 15.2.0 | `C:\msys64` (MSYS2 20251213) |
| GCC (WSL Ubuntu) | 13.3.0 | inside WSL |
| MSVC toolset | VS 2019 Build Tools (vctools workload), VC++ 2015-2022 Redist 14.42 | choco |
| Windows SDK | 10.0.19041.685 | winget `Microsoft.WindowsSDK.10.0.19041` |

## 3. Build tools and package managers

| Tool | Version | Location |
|---|---|---|
| Apache Maven | 3.9.11 | `C:\maven3` (`MAVEN_HOME`, hand-extracted) |
| MSYS2 make / autoconf / automake / libtool / pkgconf | make 4.4.1 | `C:\msys64` (`pacman -Qe`) |
| winget | 1.29.290 | App Installer |
| Chocolatey | 2.4.1 | `C:\ProgramData\chocolatey` |
| npm | 11.6.2 | with Node |
| pip / uv | 26.1.2 / 0.11.28 | see above |

## 4. Version control

| Tool | Version | Source |
|---|---|---|
| Git for Windows | 2.47.1.windows.2 | winget `Git.Git` (update 2.55 available) |
| Git LFS | 3.6.1 | bundled with Git; global filters configured |
| GitHub CLI | 2.83.2 | winget `GitHub.cli` **and** choco `gh` (duplicate) |
| Git (MSYS2) | 2.53.0 | `C:\msys64` |
| Git (WSL) | 2.43.0 | Ubuntu |

Global git identity: `Sankha Ray` / `saheb_ray85@yahoo.co.in`.

## 5. Containers, cloud, infrastructure

| Tool | Version | Source |
|---|---|---|
| Docker Desktop | 4.81.0 (engine 29.6.1, Compose 5.2.0) | winget `Docker.DockerDesktop`; contexts `default`, `desktop-linux` (active) |
| kubectl | 1.36.1 client | bundled with Docker Desktop |
| WSL 2 | 2.6.1.0 | distros: `Ubuntu` 24.04.4 LTS, `docker-desktop` |
| AWS CLI v2 | 2.32.22 (bundles Python 3.13.11) | winget `Amazon.AWSCLI`; profiles `sharanaya_boutique`, `prod`, `sandbox` |
| Terraform | 1.15.5 | `C:\terraform_1.15.5_windows_amd64` (hand-extracted) |
| cloudflared | 2025.8.1 | winget `Cloudflare.cloudflared` |

## 6. AI coding tools

| Tool | Version | Source |
|---|---|---|
| Claude Code CLI | 2.1.277 | `%USERPROFILE%\.local\bin\claude.exe` |
| Claude desktop app | 1.52386.3 | winget `Anthropic.Claude` |
| GitHub Copilot CLI | 1.0.21 (npm) and 1.0.10 (winget) | duplicate; npm copy wins on PATH |
| OpenAI Codex CLI | 0.144.1 | npm `@openai/codex` |
| Antigravity | 2.0.6 | see IDEs |
| graphify | 0.9.15 | `uv tool` (`graphify`, `graphify-mcp`) |

Claude Code plugins installed (names only): aws-core, aws-serverless, claude-code-setup,
code-simplifier, commit-commands, context7, deploy-on-aws, figma, frontend-design (two
marketplaces), github, playwright, ponytail, security-guidance, skill-creator, superpowers.
Extra marketplaces: `claude-skills`, `agent-toolkit-for-aws`, `ponytail`. User-level MCP
server: `aws-mcp`. GSD hooks and statusline are wired to Node.

## 7. Global language packages

npm global: `@fission-ai/openspec` 1.4.1, `@github/copilot` 1.0.21, `@gsd-build/sdk` 0.1.0,
`@openai/codex` 0.144.1, `claudekit-cli` 3.35.0, `react-devtools` 7.0.1, `uipro-cli` 2.2.3.

pip (Python 3.11): pytest 9.1.1, ruff 0.15.7, requests 2.34.2, openpyxl 3.1.5, PyYAML 6.0.3,
python-dotenv 1.2.2, Pygments 2.21.0, plus transitive deps (certifi, charset-normalizer,
colorama, defusedxml, et_xmlfile, idna, iniconfig, packaging, pluggy, urllib3).

## 8. IDE extensions

VS Code (21): anthropic.claude-code, eamodio.gitlens, github.vscode-github-actions,
kevinrose.vsc-python-indent, marcovr.actions-shell-scripts, mechatroner.rainbow-csv,
mgesbert.python-path, ms-azuretools.vscode-containers, ms-edgedevtools.vscode-edge-devtools,
ms-python.debugpy, ms-python.python, ms-python.vscode-pylance, ms-vscode-remote.remote-containers,
ms-vscode-remote.remote-ssh, ms-vscode-remote.remote-ssh-edit, ms-vscode.powershell,
ms-vscode.remote-explorer, ms-vscode.remote-server, nickcernis.github-cli-ui,
oleg-shilo.cs-script, sbluemin.github-copilot-cli-agents.

Antigravity (`~/.antigravity/extensions`, not VS Code): Claude Code, GitLens, GitHub Actions,
Go, Gemini CLI companion, Gemini Code Assist, clangd, pyrefly, Containers, Docker, Playwright,
Python + debugpy + python-envs, PHP Tools suite (devsense), Red Hat Java, Java pack
(debug, dependency, test, maven, gradle).

IntelliJ 2026.1: no third-party plugins directory found (bundled only).

## 9. CLI utilities

7-Zip 26.02, jq 1.8.1, FFmpeg 8.0.1 (essentials), Tesseract OCR 5.4.0, WinRAR 7.13,
curl / ssh / openssl (Git for Windows bundle), Windows OpenSSH.
Browsers for web dev: Chrome 153, Edge 153.

## 10. Security and system protection (non-dev, essential)

| Category | Product | Version | Status / notes |
|---|---|---|---|
| Antivirus | Norton 360 | 26.8.11125.2681 | Registered AV in Windows Security Center; services `Norton Antivirus`, `Norton Tools`, `NortonWscReporter` running |
| Antivirus (built-in) | Microsoft Defender Antivirus | platform 4.18.25010.11 | **Disabled** (AntivirusEnabled=False, RealTimeProtection=False, `WinDefend` stopped); expected while Norton is the registered AV |
| Firewall | Norton Firewall | (Norton 360) | Registered firewall product; service running |
| Firewall (built-in) | Windows Defender Firewall | OS | Service `mpssvc` running; Domain, Private and Public profiles all Enabled |
| VPN | Surfshark | 6.18.0999 | winget `Surfshark.Surfshark`; `Surfshark Service` running; OpenVPN Data Channel Offload adapter (disconnected) |
| VPN | Norton VPN | (Norton 360) | Service `NortonVpn` running |
| Zero Trust / SASE | none found | | No Zscaler, Pulse Secure / Ivanti, GlobalProtect, Cisco AnyConnect / Secure Client, Netskope, Cloudflare WARP, Tailscale or ZeroTier. `cloudflared` is a tunnel CLI, not a zero-trust client |
| Disk encryption | BitLocker | OS | C: and D: ProtectionStatus On, 100% encrypted, FullyEncrypted (verified 2026-09-20 in an elevated shell) |
| Archivers | 7-Zip | 26.02 | winget `7zip.7zip` (update 26.03 available); not on PATH |
| Archivers | WinRAR | 7.13 | winget `RARLab.WinRAR` (update 7.23 available) + shell-extension MSIX |
| Archivers (CLI) | tar, unzip, gzip | Git for Windows bundle | on PATH via `C:\Program Files\Git\usr\bin` |
| Remote access | TeamViewer | 15.81.5 | winget `TeamViewer.TeamViewer` |
| Windows VPN profiles | none | | `Get-VpnConnection` empty; only stock WAN Miniport adapters |

## 11. Collaboration, productivity, cloud storage

| Category | Product | Version | Source |
|---|---|---|---|
| Office suite | Microsoft Office Enterprise 2007 + SP3 | 12.0.6612.1000 | legacy 32-bit installer, ~60 KB security updates listed by winget |
| Office suite | Apache OpenOffice | 4.1.16 | winget `Apache.OpenOffice` |
| Office (M365) | Microsoft 365 Copilot app | 19.2609.37021 | winget `Microsoft.365Copilot` |
| Email | Outlook for Windows | 1.2025.109.100 | winget `Microsoft.Outlook` (update available) |
| Notes | OneNote for Windows 10 | 16.14326 | MSIX |
| Meetings | Zoom Workplace | 7.0.6 | winget `Zoom.Zoom.EXE` (update 7.1.8) |
| Meetings / chat | Microsoft Teams | 26225.1806 | winget `Microsoft.Teams` + Office meeting add-in |
| Chat | WhatsApp Desktop | 2.2635.100 | MSIX (Store) |
| Chat | Skype | 15.150.3125 | MSIX (Store) |
| Cloud storage | Google Drive for desktop | 130.0.2.0 | winget `Google.GoogleDrive` |
| Cloud storage | Microsoft OneDrive | 26.158.0816 | winget `Microsoft.OneDrive` + sync MSIX |
| PDF | Adobe Acrobat (64-bit) + Acrobat Reader | 26.002.21931 / 26.0.0.1 | installer + two MSIX |
| Browsers | Google Chrome, Microsoft Edge | 153 / 153 | winget |
| Media | VLC, FFmpeg, Clipchamp | 3.0.23 / 8.0.1 / 4.5 | winget / MSIX |
| Other | LinkedIn, hPanel (Hostinger), Google One, YouTube PWA | | MSIX / PWA shortcuts |

## 12. Checklist against the requested categories

| Requested item | Found | Detail |
|---|---|---|
| Antivirus | Yes | Norton 360 (active); Defender present but disabled |
| VPN | Yes | Surfshark; Norton VPN service |
| Zero Trust (Zscaler, Pulse Secure) | No | none installed |
| Zip | Yes | 7-Zip 26.02, WinRAR 7.13, tar/unzip/gzip (Git) |
| Git / GitHub / Git Bash | Yes | Git 2.47.1 (with Git Bash, LFS 3.6.1), GitHub CLI 2.83.2, GitHub PWA, GitLens |
| MS Office | Yes | Office 2007 Enterprise (legacy), M365 Copilot app, Outlook, OneNote; OpenOffice 4.1.16 |
| Zoom | Yes | Zoom Workplace 7.0.6 |
| WhatsApp | Yes | WhatsApp Desktop 2.2635 |
| PowerShell | Yes | PowerShell 7.6.6 + Windows PowerShell 5.1 |
| Postman | Yes | 12.28.6 |
| Node.js | Yes | 24.12.0, npm 11.6.2 |
| MSYS2 | Yes | 20251213 at `C:\msys64` (gcc 15.2, make, autotools) |
| jq | Yes | 1.8.1 |
| Google Drive | Yes | Drive for desktop 130.0.2.0 |
| ffmpeg | Yes | 8.0.1 essentials |
| AI CLIs (Copilot, Claude, GitHub) | Yes | Copilot CLI 1.0.21, Claude Code 2.1.277, Codex CLI 0.144.1, gh 2.83.2; plus Claude desktop, Antigravity |
| 7zip | Yes | 26.02 |

## 13. WSL Ubuntu 24.04 contents

Manual apt packages are the base image plus `python3`, `python3-pip`, `wslu`. Toolchain
present: Python 3.12.3, gcc 13.3.0, make, git 2.43.0. Docker via Desktop integration.
No node, java, nvm, sdkman, cargo, go, or pyenv inside WSL.

## 14. Windows optional features (enabled)

From `Get-WindowsOptionalFeature -Online` run as Administrator on 2026-09-20.

| Feature | Why it matters |
|---|---|
| Microsoft-Windows-Subsystem-Linux | Required by WSL 2 |
| VirtualMachinePlatform | Required by WSL 2 and Docker Desktop's WSL backend |
| NetFx4-AdvSrvs, WCF-Services45, WCF-TCP-PortSharing45 | .NET Framework 4.x advanced services and WCF |
| Microsoft-RemoteDesktopConnection, MSRDC-Infrastructure | Remote Desktop client |
| SmbDirect, WorkFolders-Client, SearchEngine-Client-Package | File sharing / search |
| MediaPlayback, WindowsMediaPlayer | Media |
| Printing-XPSServices-Features, Printing-PrintToPDFServices-Features, Printing-Foundation-Features, Printing-Foundation-InternetPrinting-Client | Printing |

Not enabled: Hyper-V, Containers, Windows Sandbox, IIS.

---

## Checked and not installed

gradle (only inside Antigravity/IntelliJ bundles), go, rustc/cargo, kotlin, ruby, php,
gcloud, az, sam, cdk, helm, pnpm, yarn, bun, deno, poetry, pipx, conda, nvm/fnm/volta,
sdkman, psql, mysql, sqlite3, redis-cli, mongosh, cmake, ninja, clang (Windows side),
scoop, protoc, flutter/dart, ollama, ngrok, pandoc.

## Could not verify

- Docker Desktop Kubernetes setting read back empty from `settings-store.json`.

