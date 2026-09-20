#Requires -Version 5.1
<#
.SYNOPSIS
    Set up a fresh Windows 11 Pro developer laptop.

.DESCRIPTION
    Installs the standard developer toolset with winget (plus Chocolatey for Apache Maven only),
    enables WSL2, writes a WSL memory cap, installs a small VS Code extension set, and prints a
    checklist of the items that need a licence, an account or a company portal.

    HOW TO RUN (as Administrator, in Windows PowerShell):
        powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1

    Or download and run in one line:
        irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/setup-employee.ps1 -OutFile setup-employee.ps1; powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1

    The first run enables Windows features and asks for a reboot. Run the script a second time
    after the reboot to finish WSL/Ubuntu. Every step is idempotent: already-installed items are
    skipped by the underlying tool, so rerunning is safe.

    Steps: features, winget, maven, java, python, vscode, msys2, wsl, wslconfig, checklist

.PARAMETER Only
    Run only these steps.
.PARAMETER Skip
    Run everything except these steps.
.PARAMETER DryRun
    Print the commands without executing them.

.EXAMPLE
    .\setup-employee.ps1 -DryRun
    .\setup-employee.ps1 -Only winget,vscode
    .\setup-employee.ps1 -Skip msys2
#>
[CmdletBinding()]
param(
    [ValidateSet('features','winget','maven','java','python','vscode','msys2','wsl','wslconfig','checklist')]
    [string[]]$Only,
    [ValidateSet('features','winget','maven','java','python','vscode','msys2','wsl','wslconfig','checklist')]
    [string[]]$Skip = @(),
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$AllSteps = 'features','winget','maven','java','python','vscode','msys2','wsl','wslconfig','checklist'
$Steps    = if ($Only) { $Only } else { $AllSteps }
$Steps    = @($Steps | Where-Object { $Skip -notcontains $_ })
$IsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
$Failures = New-Object System.Collections.Generic.List[string]
$RebootNeeded = $false
$RunAsFile = [bool]$MyInvocation.MyCommand.Path

# ---------------------------------------------------------------- package lists
$WingetIds = @(
    # Security and protection
    '7zip.7zip', 'Surfshark.Surfshark',
    # Editors and IDEs
    'JetBrains.IntelliJIDEA', 'Microsoft.VisualStudioCode', 'Notepad++.Notepad++',
    'DBeaver.DBeaver.Community', 'Postman.Postman', 'WinMerge.WinMerge',
    # Languages and runtimes
    'Oracle.JDK.25', 'OpenJS.NodeJS.LTS', 'Python.PythonInstallManager', 'astral-sh.uv',
    'Microsoft.PowerShell', 'MSYS2.MSYS2',
    # Version control
    'Git.Git', 'GitHub.GitLFS', 'GitHub.cli',
    # Containers, cloud and infrastructure
    'Docker.DockerDesktop', 'Microsoft.WSL', 'Amazon.AWSCLI', 'Hashicorp.Terraform',
    # AI coding tools
    'Anthropic.Claude', 'Anthropic.ClaudeCode', 'GitHub.Copilot', 'OpenAI.Codex',
    # Command-line utilities
    'jqlang.jq', 'Gyan.FFmpeg',
    # Office and collaboration (Microsoft.Office = Microsoft 365 Apps: Outlook, OneNote, Word, Excel...)
    'Microsoft.Office', 'Microsoft.Teams', 'Zoom.Zoom', 'Adobe.Acrobat.Reader.64-bit'
)
$WhatsAppStoreId = '9NKSQGP7F2NH'   # WhatsApp Desktop, Microsoft Store source
$VsCodeExtensions = @(
    'anthropic.claude-code', 'github.copilot', 'github.copilot-chat', 'ms-python.python',
    'vscjava.vscode-java-pack', 'ms-azuretools.vscode-containers', 'eamodio.gitlens', 'ms-vscode.powershell'
)
$Msys2Packages = 'gcc','make','autoconf','automake','libtool','pkgconf'
$UbuntuDistro  = 'Ubuntu-24.04'
$WslConfig = @"
[wsl2]
memory=6GB
processors=4
swap=2GB
"@

# ---------------------------------------------------------------- helpers
function Write-Step([string]$Name) { Write-Host "`n=== $Name ===" -ForegroundColor Cyan }
function Write-Note([string]$Text) { Write-Host "  $Text" -ForegroundColor Yellow }
function Test-Cmd([string]$Name)   { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}
function Invoke-Cmd {
    param([string]$Display, [scriptblock]$Action, [switch]$Soft)
    Write-Host "  > $Display"
    if ($DryRun) { return }
    $global:LASTEXITCODE = 0
    try {
        & $Action
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            if ($Soft) { Write-Note "$Display failed (exit $LASTEXITCODE); continue manually." }
            else       { $Failures.Add("$Display (exit $LASTEXITCODE)") }
        }
    } catch {
        if ($Soft) { Write-Note "$Display failed ($($_.Exception.Message)); continue manually." }
        else       { $Failures.Add("$Display ($($_.Exception.Message))") }
    }
}
function Install-WingetPackage([string]$Id, [string]$Source = 'winget', [switch]$Soft) {
    Invoke-Cmd "winget install --id $Id" -Soft:$Soft {
        winget install --id $Id --exact --source $Source --accept-source-agreements --accept-package-agreements --no-upgrade --disable-interactivity
    }
}

Write-Host "setup-employee.ps1  admin=$IsAdmin  dryrun=$DryRun"
Write-Host "steps: $($Steps -join ', ')"
if (-not $IsAdmin -and -not $DryRun) {
    Write-Host 'This script must be run from an elevated (Administrator) PowerShell. Right-click PowerShell, "Run as administrator", then rerun.' -ForegroundColor Red
    return
}

# ---------------------------------------------------------------- features
if ($Steps -contains 'features') {
    Write-Step 'features: Windows Subsystem for Linux + Virtual Machine Platform'
    foreach ($feature in 'Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform') {
        if (-not $DryRun) {
            $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue).State
            if ($state -eq 'Enabled') { Write-Host "  $feature already enabled"; continue }
        }
        Invoke-Cmd "Enable-WindowsOptionalFeature $feature" {
            $r = Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All
            if ($r.RestartNeeded) { $script:RebootNeeded = $true }
        }
        if ($DryRun) { $RebootNeeded = $true }
    }
}

# ---------------------------------------------------------------- winget
if ($Steps -contains 'winget') {
    Write-Step 'winget: applications'
    if (-not (Test-Cmd winget)) {
        Write-Note 'winget not found. Install "App Installer" from the Microsoft Store (or run Windows Update), then rerun.'
        $Failures.Add('winget missing')
    } else {
        foreach ($id in $WingetIds) { Install-WingetPackage $id }
        Install-WingetPackage $WhatsAppStoreId -Source msstore -Soft
        Write-Note 'If WhatsApp failed above, install "WhatsApp" from the Microsoft Store by hand.'
        Update-SessionPath
    }
}

# ---------------------------------------------------------------- maven
if ($Steps -contains 'maven') {
    Write-Step 'maven: Apache Maven via Chocolatey (not available in winget)'
    if (-not (Test-Cmd choco)) {
        Invoke-Cmd 'install Chocolatey from community.chocolatey.org/install.ps1' {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        Update-SessionPath
    }
    if ((Test-Cmd choco) -or $DryRun) {
        Invoke-Cmd 'choco install maven -y' { choco install maven -y --no-progress }
        Update-SessionPath
    } else {
        Write-Note 'Chocolatey unavailable; install Apache Maven 3.9 by hand from https://maven.apache.org/download.cgi'
        $Failures.Add('maven: choco missing')
    }
}

# ---------------------------------------------------------------- java
if ($Steps -contains 'java') {
    Write-Step 'java: JAVA_HOME and PATH for JDK 25'
    $jdk = Get-ChildItem 'C:\Program Files\Java' -Directory -Filter 'jdk-25*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $jdk) {
        if ($DryRun) { $jdk = [pscustomobject]@{ FullName = 'C:\Program Files\Java\jdk-25' } }
        else { Write-Note 'JDK 25 not found under C:\Program Files\Java. Run the winget step first.'; $Failures.Add('java: JDK 25 missing') }
    }
    if ($jdk) {
        Invoke-Cmd "set JAVA_HOME=$($jdk.FullName)" {
            [Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk.FullName, 'Machine')
            $machinePath = [Environment]::GetEnvironmentVariable('Path','Machine')
            if (($machinePath -split ';') -notcontains '%JAVA_HOME%\bin') {
                [Environment]::SetEnvironmentVariable('Path', ($machinePath.TrimEnd(';') + ';%JAVA_HOME%\bin'), 'Machine')
            }
        }
        Update-SessionPath
    }
}

# ---------------------------------------------------------------- python
if ($Steps -contains 'python') {
    Write-Step 'python: Python 3.11 via Python Install Manager'
    Update-SessionPath
    if ((Test-Cmd py) -or $DryRun) {
        Invoke-Cmd 'py install 3.11' { py install 3.11 }
    } else {
        Write-Note 'Python Install Manager (py) not found. Run the winget step first, then rerun.'
        $Failures.Add('python: py missing')
    }
}

# ---------------------------------------------------------------- vscode
if ($Steps -contains 'vscode') {
    Write-Step 'vscode: extensions'
    Update-SessionPath
    if ((Test-Cmd code) -or $DryRun) {
        foreach ($ext in $VsCodeExtensions) {
            Invoke-Cmd "code --install-extension $ext" { code --install-extension $ext --force }
        }
    } else {
        Write-Note 'VS Code "code" CLI not found. Run the winget step first, then rerun.'
        $Failures.Add('vscode: code missing')
    }
}

# ---------------------------------------------------------------- msys2
if ($Steps -contains 'msys2') {
    Write-Step 'msys2: gcc, make, autotools, pkgconf'
    $bash = 'C:\msys64\usr\bin\bash.exe'
    if ((Test-Path $bash) -or $DryRun) {
        # First update may replace core packages and end the shell; running twice is the documented pattern.
        Invoke-Cmd 'pacman -Syu --noconfirm (core update, pass 1)' { & $bash -lc 'pacman -Syu --noconfirm' }
        Invoke-Cmd 'pacman -Syu --noconfirm (pass 2)'              { & $bash -lc 'pacman -Syu --noconfirm' }
        Invoke-Cmd "pacman -S --needed --noconfirm $($Msys2Packages -join ' ')" {
            & $bash -lc "pacman -S --needed --noconfirm $($Msys2Packages -join ' ')"
        }
    } else {
        Write-Note "MSYS2 not found at C:\msys64. Run the winget step first, then rerun."
        $Failures.Add('msys2: not installed')
    }
}

# ---------------------------------------------------------------- wsl
if ($Steps -contains 'wsl') {
    Write-Step "wsl: $UbuntuDistro"
    if ($RebootNeeded -and -not $DryRun) {
        Write-Note 'Windows features were just enabled. Reboot, then rerun this script to install Ubuntu.'
    } elseif (-not (Test-Cmd wsl)) {
        Write-Note 'wsl.exe not found. Reboot after the features step, then rerun.'
        $Failures.Add('wsl missing')
    } else {
        $distros = ((wsl --list --quiet 2>$null) | Out-String) -replace "`0", ''
        if ($distros -match "(?m)^$([regex]::Escape($UbuntuDistro))\s*$") {
            Write-Host "  $UbuntuDistro already installed"
        } else {
            Invoke-Cmd "wsl --install -d $UbuntuDistro --no-launch" { wsl --install -d $UbuntuDistro --no-launch }
            Write-Note "Open '$UbuntuDistro' from the Start menu once to create the Linux user."
        }
    }
}

# ---------------------------------------------------------------- wslconfig
if ($Steps -contains 'wslconfig') {
    Write-Step 'wslconfig: cap WSL2 memory so Docker does not starve Windows'
    $cfg = Join-Path $env:USERPROFILE '.wslconfig'
    if (Test-Path $cfg) {
        Write-Host "  $cfg already exists; left unchanged"
    } else {
        Invoke-Cmd "write $cfg (memory=6GB processors=4 swap=2GB)" { Set-Content -Path $cfg -Value $WslConfig -Encoding ASCII }
    }
}

# ---------------------------------------------------------------- checklist
if ($Steps -contains 'checklist') {
    Write-Step 'checklist: do these by hand'
    $items = @(
        'Norton 360: sign in at my.norton.com, download the installer, install and activate with the licence.',
        'Zscaler Client Connector: download from the company portal, install, sign in with the work account.',
        'Microsoft 365: open Word or Outlook, sign in with the work account to activate; sign in to Teams.',
        'Surfshark: open the app and sign in with the licence account.',
        'BitLocker: in an admin PowerShell run  Enable-BitLocker -MountPoint C: -TpmProtector -UsedSpaceOnly ; then  Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector  and save the recovery key somewhere safe (not on this laptop). Repeat for any other drive.',
        'Docker Desktop: launch once, accept the licence, confirm "Use the WSL 2 based engine". If the daily login is not an administrator, add it to the local "docker-users" group.',
        "Ubuntu: open '$UbuntuDistro' from the Start menu once to create the Linux user.",
        'Git: run  git config --global user.name "<name>"  and  git config --global user.email "<email>" .',
        'GitHub CLI, Claude Code, Copilot CLI, Codex CLI: run  gh auth login ,  claude ,  copilot ,  codex  once to sign in.',
        'Windows Update: install all pending updates.'
    )
    $i = 1
    foreach ($item in $items) { Write-Host ("  {0,2}. {1}" -f $i, $item); $i++ }
    if ($RebootNeeded) { Write-Host "`n  REBOOT NOW, then run this script again to finish WSL/Ubuntu." -ForegroundColor Magenta }
}

# ---------------------------------------------------------------- summary
Write-Host ''
if ($Failures.Count -eq 0) {
    Write-Host 'setup-employee finished with no failures.' -ForegroundColor Green
} else {
    Write-Host "setup-employee finished with $($Failures.Count) issue(s):" -ForegroundColor Red
    $Failures | ForEach-Object { Write-Host "  - $_" }
    if ($RunAsFile) { exit 1 }
}
