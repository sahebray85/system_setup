# Software List for Laptop Setup

Please install the following on the new laptop (Windows 11 Pro, 64-bit). Latest stable
versions are fine unless a version is noted. Items marked **(admin)** need an administrator
account to install.

## Security and protection
- Norton 360 (antivirus, firewall, VPN) **(admin)**
- Surfshark VPN (or Similar)
- ZScalar (Zero Trust)
- BitLocker enabled on all drives **(admin)**
- 7-Zip

## Editors and IDEs
- JetBrains IntelliJ IDEA (2026.1 or newer)
- Microsoft Visual Studio Code
- Notepad++
- DBeaver Community
- Postman
- WinMerge

## Programming languages and runtimes
- Oracle JDK 25 (LTS)
- Node.js 24 LTS (includes npm)
- Python 3.11 via Python Install Manager, plus `uv`
- PowerShell 7
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

## AI coding tools
- Claude (desktop app) and Claude Code CLI
- GitHub Copilot CLI
- OpenAI Codex CLI

## Command-line utilities
- jq
- FFmpeg

## Office, collaboration and cloud storage
- Microsoft 365 (Outlook, OneNote, Teams, Office apps)
- Zoom Workplace
- WhatsApp Desktop
- Adobe Acrobat Reader

## Notes for the vendor
- Please do not sign in to any personal or company accounts; the user will do that.
- Please leave installers' default locations unless noted.
- Everything above except Norton, Zscaler, BitLocker and account sign-ins can be installed by
  one script. In an Administrator PowerShell run:
  ```
  irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/setup-employee.ps1 -OutFile setup-employee.ps1; powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1
  ```
  Reboot when it asks, run it once more, then work through the checklist it prints.
