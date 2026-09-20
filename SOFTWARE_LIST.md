# Software List for Laptop Setup

Please install the following on the new laptop (Windows 11 Pro, 64-bit). Latest stable
versions are fine unless a version is noted. Items marked **(admin)** need an administrator
account to install.

## Security and protection
- Norton 360 (antivirus, firewall, VPN) **(admin)**
- Surfshark VPN
- BitLocker enabled on all drives **(admin)**
- Windows Defender Firewall left enabled
- 7-Zip
- WinRAR

## Editors and IDEs
- JetBrains IntelliJ IDEA (2026.1 or newer)
- Microsoft Visual Studio Code
- Google Antigravity
- Notepad++
- DBeaver Community
- Postman
- WinMerge
- Windows Terminal

## Programming languages and runtimes
- Oracle JDK 25 (LTS), plus OpenJDK 17 and 21 (LTS)
- Node.js 24 LTS (includes npm)
- Python 3.11 via Python Install Manager, plus `uv`
- PowerShell 7
- Microsoft .NET 7 Runtime
- Microsoft Visual Studio 2019 Build Tools with C++ workload **(admin)**
- Windows 10 SDK (10.0.19041)
- MSYS2 (with gcc, make, autoconf, automake, libtool, pkgconf)

## Build tools and package managers
- Apache Maven 3.9
- Chocolatey **(admin)**
- winget (App Installer from Microsoft Store)

## Version control
- Git for Windows (with Git Bash and Git LFS)
- GitHub CLI (`gh`)

## Containers, cloud and infrastructure
- Docker Desktop **(admin)**
- Windows Subsystem for Linux 2 with Ubuntu 24.04 **(admin)**
- Windows features enabled: Windows Subsystem for Linux, Virtual Machine Platform **(admin)**
- AWS CLI v2
- HashiCorp Terraform
- Cloudflare `cloudflared`

## AI coding tools
- Claude (desktop app) and Claude Code CLI
- GitHub Copilot CLI
- OpenAI Codex CLI

## Command-line utilities
- jq
- FFmpeg
- Tesseract OCR

## Office, collaboration and cloud storage
- Microsoft 365 (Outlook, OneNote, Teams, Office apps)
- Apache OpenOffice
- Zoom Workplace
- WhatsApp Desktop
- Skype
- Google Drive for desktop
- Microsoft OneDrive
- Adobe Acrobat Reader
- Google Chrome
- Microsoft Edge
- VLC media player
- TeamViewer

## Notes for the vendor
- Please do not sign in to any personal or company accounts; the user will do that.
- Please leave installers' default locations unless noted.
- A full versioned inventory and an automated install script are kept in this repository
  (`INVENTORY.md`, `bootstrap.ps1`) if you prefer to script the setup.
