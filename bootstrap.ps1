#Requires -Version 5.1
<#
.SYNOPSIS
    Reinstall the workstation software recorded in exports/ on a fresh Windows machine.

.DESCRIPTION
    Replays every export file produced for INVENTORY.md:
      winget      exports/winget-dev.json            (winget import)
      choco       exports/choco-packages.config      (choco install; installs Chocolatey first if missing)
      unmanaged   JDK 25, Node LTS, Terraform, MSYS2, uv, Postman via winget; Maven via choco
      npm         exports/npm-global.txt             (npm install -g)
      python      exports/pip-3.11.txt               (py install 3.11, then pip install -r)
      uv          exports/uv-tools.txt               (uv tool install)
      vscode      exports/vscode-extensions.txt      (code --install-extension)
      antigravity exports/antigravity-extensions.txt (prints the list; Antigravity has no CLI installer)
      msys2       exports/msys2-packages.txt         (pacman -S --needed)
      wsl         exports/wsl-ubuntu-apt.txt         (wsl --install Ubuntu, then apt-get install)

    Every step is idempotent: already-installed items are skipped by the underlying tool.
    Steps that need Administrator (Chocolatey bootstrap, wsl --install) are skipped with a
    warning when the shell is not elevated.

.PARAMETER Only
    Run only these steps.
.PARAMETER Skip
    Run everything except these steps.
.PARAMETER DryRun
    Print the commands without executing them.

.EXAMPLE
    .\bootstrap.ps1 -DryRun
    .\bootstrap.ps1 -Only winget,npm
    .\bootstrap.ps1 -Skip wsl,msys2
#>
[CmdletBinding()]
param(
    [ValidateSet('winget','choco','unmanaged','npm','python','uv','vscode','antigravity','msys2','wsl')]
    [string[]]$Only,
    [ValidateSet('winget','choco','unmanaged','npm','python','uv','vscode','antigravity','msys2','wsl')]
    [string[]]$Skip = @(),
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$Exports  = Join-Path $PSScriptRoot 'exports'
$AllSteps = 'winget','choco','unmanaged','npm','python','uv','vscode','antigravity','msys2','wsl'
$Steps    = if ($Only) { $Only } else { $AllSteps }
$Steps    = @($Steps | Where-Object { $Skip -notcontains $_ })
$IsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
$Failures = New-Object System.Collections.Generic.List[string]
$AnsiEscape = [regex]"$([char]27)\[[0-9;]*m"

function Write-Step([string]$Name) { Write-Host "`n=== $Name ===" -ForegroundColor Cyan }
function Write-Note([string]$Text) { Write-Host "  $Text" -ForegroundColor Yellow }
function Test-Cmd([string]$Name)   { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}
function Invoke-Cmd {
    param([string]$Display, [scriptblock]$Action)
    Write-Host "  > $Display"
    if ($DryRun) { return }
    $global:LASTEXITCODE = 0
    try {
        & $Action
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { $Failures.Add("$Display (exit $LASTEXITCODE)") }
    } catch {
        $Failures.Add("$Display ($($_.Exception.Message))")
    }
}
function Read-Lines([string]$File) {
    # Returns trimmed, non-empty, non-comment lines with any terminal colour codes removed.
    $p = Join-Path $Exports $File
    if (-not (Test-Path $p)) { Write-Note "missing $p"; return @() }
    Get-Content $p | ForEach-Object { $AnsiEscape.Replace($_, '').Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
}

Write-Host "bootstrap.ps1  exports=$Exports  admin=$IsAdmin  dryrun=$DryRun"
Write-Host "steps: $($Steps -join ', ')"

# ---------------------------------------------------------------- winget
if ($Steps -contains 'winget') {
    Write-Step 'winget: import exports/winget-dev.json'
    if (-not (Test-Cmd winget)) {
        Write-Note 'winget not found. Install "App Installer" from the Microsoft Store, then rerun.'
        $Failures.Add('winget missing')
    } else {
        $f = Join-Path $Exports 'winget-dev.json'
        Invoke-Cmd "winget import -i $f" {
            winget import -i $f --accept-source-agreements --accept-package-agreements --ignore-unavailable --no-upgrade --disable-interactivity
        }
        Update-SessionPath
    }
}

# ---------------------------------------------------------------- choco
if ($Steps -contains 'choco') {
    Write-Step 'choco: install exports/choco-packages.config'
    if (-not (Test-Cmd choco)) {
        if ($IsAdmin -or $DryRun) {
            Invoke-Cmd 'install Chocolatey from community.chocolatey.org/install.ps1' {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }
            Update-SessionPath
        } else {
            Write-Note 'Chocolatey is not installed and this shell is not elevated. Rerun as Administrator.'
            $Failures.Add('choco step skipped (needs admin)')
        }
    }
    if (Test-Cmd choco) {
        $f = Join-Path $Exports 'choco-packages.config'
        Invoke-Cmd "choco install $f -y" { choco install $f -y --no-progress }
        Update-SessionPath
    }
}

# ---------------------------------------------------------------- unmanaged
if ($Steps -contains 'unmanaged') {
    Write-Step 'unmanaged: tools that were hand-installed on the original machine'
    Write-Note 'Original locations were C:\Java25, C:\maven3, C:\terraform_*, C:\msys64. winget/choco install'
    Write-Note 'elsewhere, so set JAVA_HOME and MAVEN_HOME afterwards if your tooling needs them.'
    if (Test-Cmd winget) {
        foreach ($id in 'Oracle.JDK.25','OpenJS.NodeJS.LTS','Hashicorp.Terraform','MSYS2.MSYS2','astral-sh.uv','Postman.Postman') {
            Invoke-Cmd "winget install --id $id" {
                winget install --id $id --exact --accept-source-agreements --accept-package-agreements --no-upgrade --disable-interactivity
            }
        }
        Update-SessionPath
    } else { $Failures.Add('unmanaged: winget missing') }
    if (Test-Cmd choco) {
        Invoke-Cmd 'choco install maven' { choco install maven -y --no-progress }
    } else { Write-Note 'choco not available; install Apache Maven manually (https://maven.apache.org/download.cgi).' }
    Write-Note 'Not scripted: OpenJDK 17/21 (winget Microsoft.OpenJDK.17 / Microsoft.OpenJDK.21) if older JDKs are needed.'
}

# ---------------------------------------------------------------- npm
if ($Steps -contains 'npm') {
    Write-Step 'npm: global packages from exports/npm-global.txt'
    Update-SessionPath
    if (-not (Test-Cmd npm)) {
        Write-Note 'npm not found. Run the "unmanaged" step (installs Node.js LTS), then rerun.'
        $Failures.Add('npm missing')
    } else {
        foreach ($pkg in Read-Lines 'npm-global.txt') {
            Invoke-Cmd "npm install -g $pkg" { npm install -g $pkg }
        }
    }
}

# ---------------------------------------------------------------- python
if ($Steps -contains 'python') {
    Write-Step 'python: Python 3.11 + exports/pip-3.11.txt'
    Update-SessionPath
    if (-not (Test-Cmd py)) {
        Write-Note 'Python Install Manager (py) not found. It is in winget-dev.json as Python.PythonInstallManager.'
        $Failures.Add('py missing')
    } else {
        Invoke-Cmd 'py install 3.11' { py install 3.11 }
        $req = Join-Path $Exports 'pip-3.11.txt'
        Invoke-Cmd "py -3.11 -m pip install -r $req" { py -3.11 -m pip install --upgrade pip; py -3.11 -m pip install -r $req }
    }
}

# ---------------------------------------------------------------- uv
if ($Steps -contains 'uv') {
    Write-Step 'uv: tools from exports/uv-tools.txt'
    Update-SessionPath
    if (-not (Test-Cmd uv)) {
        Write-Note 'uv not found. Run the "unmanaged" step (winget astral-sh.uv), then rerun.'
        $Failures.Add('uv missing')
    } else {
        # Use the Windows certificate store: security software on the original machine re-signs
        # HTTPS, and uv's bundled CA list then rejects pypi.org with "UnknownIssuer".
        $env:UV_SYSTEM_CERTS = '1'
        # File format: "<tool> v<version>" lines, followed by "- <entrypoint>" lines to ignore.
        foreach ($line in @(Read-Lines 'uv-tools.txt' | Where-Object { $_ -notmatch '^-' })) {
            if ($line -match '^(\S+)\s+v(\S+)') {
                $spec = "$($Matches[1])==$($Matches[2])"
                Invoke-Cmd "uv tool install $spec" { uv tool install $spec }
            }
        }
    }
}

# ---------------------------------------------------------------- vscode
if ($Steps -contains 'vscode') {
    Write-Step 'vscode: extensions from exports/vscode-extensions.txt'
    Update-SessionPath
    if (-not (Test-Cmd code)) {
        Write-Note 'VS Code "code" CLI not found (winget Microsoft.VisualStudioCode). Rerun after it is installed.'
        $Failures.Add('code missing')
    } else {
        foreach ($ext in Read-Lines 'vscode-extensions.txt') {
            Invoke-Cmd "code --install-extension $ext" { code --install-extension $ext --force }
        }
    }
}

# ---------------------------------------------------------------- antigravity
if ($Steps -contains 'antigravity') {
    Write-Step 'antigravity: extensions from exports/antigravity-extensions.txt'
    # Folder names look like publisher.name-1.2.3-universal; reduce to publisher.name.
    $ids = @(Read-Lines 'antigravity-extensions.txt' | ForEach-Object { $_ -replace '-\d+\.\d+\.\d+.*$','' } | Sort-Object -Unique)
    if (Test-Cmd antigravity) {
        foreach ($id in $ids) { Invoke-Cmd "antigravity --install-extension $id" { antigravity --install-extension $id --force } }
    } else {
        Write-Note 'Antigravity has no extension CLI on PATH. Install these from its Extensions view:'
        $ids | ForEach-Object { Write-Host "    $_" }
    }
}

# ---------------------------------------------------------------- msys2
if ($Steps -contains 'msys2') {
    Write-Step 'msys2: packages from exports/msys2-packages.txt'
    $pacman = 'C:\msys64\usr\bin\pacman.exe'
    if (-not (Test-Path $pacman)) {
        Write-Note "pacman not found at $pacman. Run the 'unmanaged' step (winget MSYS2.MSYS2) first."
        $Failures.Add('msys2 missing')
    } else {
        # File format: "<package> <version>"; version is dropped, pacman installs current.
        $names = @(Read-Lines 'msys2-packages.txt' | ForEach-Object { ($_ -split '\s+')[0] })
        Invoke-Cmd "pacman -S --needed --noconfirm $($names -join ' ')" { & $pacman -S --needed --noconfirm @names }
    }
}

# ---------------------------------------------------------------- wsl
if ($Steps -contains 'wsl') {
    Write-Step 'wsl: Ubuntu + exports/wsl-ubuntu-apt.txt'
    if (-not (Test-Cmd wsl)) {
        Write-Note 'wsl.exe not found. Enable Windows Subsystem for Linux, then rerun.'
        $Failures.Add('wsl missing')
    } else {
        $distros = ((wsl --list --quiet 2>$null) | Out-String) -replace "`0", ''
        if ($distros -notmatch '(?m)^Ubuntu\s*$') {
            if ($IsAdmin -or $DryRun) {
                Invoke-Cmd 'wsl --install -d Ubuntu --no-launch' { wsl --install -d Ubuntu --no-launch }
                Write-Note 'A reboot and a first launch of Ubuntu (to create the user) may be needed before apt packages install.'
            } else {
                Write-Note 'Ubuntu is not installed and this shell is not elevated. Rerun as Administrator.'
                $Failures.Add('wsl install skipped (needs admin)')
            }
        }
        $pkgs = (Read-Lines 'wsl-ubuntu-apt.txt') -join ' '
        if ($pkgs) {
            Invoke-Cmd "wsl -d Ubuntu apt-get install -y $pkgs" {
                wsl -d Ubuntu -e bash -lc "sudo apt-get update -qq && sudo apt-get install -y $pkgs"
            }
        }
    }
}

# ---------------------------------------------------------------- summary
Write-Host ''
if ($Failures.Count -eq 0) {
    Write-Host 'bootstrap finished with no failures.' -ForegroundColor Green
} else {
    Write-Host "bootstrap finished with $($Failures.Count) issue(s):" -ForegroundColor Red
    $Failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
