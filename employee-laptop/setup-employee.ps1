#Requires -Version 5.1
<#
.SYNOPSIS
    Set up a fresh Windows 11 Pro developer laptop.

.DESCRIPTION
    Installs the standard developer toolset with winget (plus Chocolatey for Apache Maven only),
    enables WSL2, writes a WSL memory cap, installs a small VS Code extension set, and prints a
    checklist of the items that need a licence, an account or a company portal.

    When it finishes it writes an HTML report (setup-employee-report.html on the Desktop) that
    lists every step as PASS or FAIL, with the exact action a person should take for each FAIL.

    HOW TO RUN: sign in to Windows as the account the employee will use every day (not a vendor
    or setup account: Ubuntu, VS Code extensions, Python and .wslconfig are per-user), open
    Windows PowerShell with "Run as administrator", then:
        powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1

    Or download and run in one line:
        irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/setup-employee.ps1 -OutFile setup-employee.ps1; powershell -ExecutionPolicy Bypass -File .\setup-employee.ps1

    The first run enables Windows features and asks for a reboot. Run the script a second time
    after the reboot to finish WSL/Ubuntu. Every step is idempotent: already-installed items are
    skipped by the underlying tool, so rerunning is safe. To keep the laptop current afterwards,
    run update-employee.ps1 from the same folder/Gist.

    Steps: features, winget, maven, java, python, vscode, msys2, wsl, wslconfig, checklist

.PARAMETER Only
    Run only these steps.
.PARAMETER Skip
    Run everything except these steps.
.PARAMETER DryRun
    Print the commands without executing them (the report is still written, marked DRYRUN).
.PARAMETER NoOpen
    Do not open the HTML report in the browser when finished.
.PARAMETER ReportPath
    Where to write the HTML report. Default: <Desktop>\setup-employee-report.html

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
    [switch]$DryRun,
    [string]$ReportPath,
    [switch]$NoOpen
)

$ErrorActionPreference = 'Continue'
$AllSteps = 'features','winget','maven','java','python','vscode','msys2','wsl','wslconfig','checklist'
$Steps    = if ($Only) { $Only } else { $AllSteps }
$Steps    = @($Steps | Where-Object { $Skip -notcontains $_ })
$IsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
$Results  = New-Object System.Collections.Generic.List[object]
$RebootNeeded = $false
$RunAsFile = [bool]$MyInvocation.MyCommand.Path
$Started  = Get-Date
if (-not $ReportPath) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) { $desktop = $env:USERPROFILE }
    $ReportPath = Join-Path $desktop 'setup-employee-report.html'
}

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
# Vendor download pages, shown in the report when a winget install fails.
$VendorUrls = @{
    '7zip.7zip'                   = 'https://www.7-zip.org/download.html'
    'Surfshark.Surfshark'         = 'https://surfshark.com/download/windows'
    'JetBrains.IntelliJIDEA'      = 'https://www.jetbrains.com/idea/download/'
    'Microsoft.VisualStudioCode'  = 'https://code.visualstudio.com/download'
    'Notepad++.Notepad++'         = 'https://notepad-plus-plus.org/downloads/'
    'DBeaver.DBeaver.Community'   = 'https://dbeaver.io/download/'
    'Postman.Postman'             = 'https://www.postman.com/downloads/'
    'WinMerge.WinMerge'           = 'https://winmerge.org/downloads/'
    'Oracle.JDK.25'               = 'https://www.oracle.com/java/technologies/downloads/'
    'OpenJS.NodeJS.LTS'           = 'https://nodejs.org/en/download'
    'Python.PythonInstallManager' = 'https://www.python.org/downloads/windows/'
    'astral-sh.uv'                = 'https://docs.astral.sh/uv/getting-started/installation/'
    'Microsoft.PowerShell'        = 'https://github.com/PowerShell/PowerShell/releases/latest'
    'MSYS2.MSYS2'                 = 'https://www.msys2.org/'
    'Git.Git'                     = 'https://git-scm.com/download/win'
    'GitHub.GitLFS'               = 'https://git-lfs.com/'
    'GitHub.cli'                  = 'https://cli.github.com/'
    'Docker.DockerDesktop'        = 'https://www.docker.com/products/docker-desktop/'
    'Microsoft.WSL'               = 'https://github.com/microsoft/WSL/releases/latest'
    'Amazon.AWSCLI'               = 'https://awscli.amazonaws.com/AWSCLIV2.msi'
    'Hashicorp.Terraform'         = 'https://developer.hashicorp.com/terraform/install'
    'Anthropic.Claude'            = 'https://claude.ai/download'
    'Anthropic.ClaudeCode'        = 'https://docs.claude.com/en/docs/claude-code/setup'
    'GitHub.Copilot'              = 'https://github.com/github/copilot-cli'
    'OpenAI.Codex'                = 'https://github.com/openai/codex'
    'jqlang.jq'                   = 'https://jqlang.org/download/'
    'Gyan.FFmpeg'                 = 'https://www.gyan.dev/ffmpeg/builds/'
    'Microsoft.Office'            = 'https://www.office.com/ (sign in, then Install apps)'
    'Microsoft.Teams'             = 'https://www.microsoft.com/microsoft-teams/download-app'
    'Zoom.Zoom'                   = 'https://zoom.us/download'
    'Adobe.Acrobat.Reader.64-bit' = 'https://get.adobe.com/reader/'
}
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
function Add-Result {
    # Every command, skip and failure is recorded here and ends up in the HTML report.
    param([string]$Step, [string]$Item, [ValidateSet('PASS','FAIL','SKIP','DRYRUN','MANUAL')][string]$Status, [string]$Detail = '', [string]$Action = '')
    $Results.Add([pscustomobject]@{ Step = $Step; Item = $Item; Status = $Status; Detail = $Detail; Action = $Action })
    if ($Status -eq 'FAIL') { Write-Note "FAILED: $Item. $Detail" }
}
function Invoke-Cmd {
    # Runs $Action and records PASS/FAIL. $Fix is the human-readable remedy shown in the report on failure.
    param([string]$Step, [string]$Display, [scriptblock]$Action, [string]$Fix = 'Rerun the script; if it fails again, run the command shown by hand in an Administrator PowerShell and read its error.')
    Write-Host "  > $Display"
    if ($DryRun) { Add-Result $Step $Display 'DRYRUN' 'Not executed (DryRun)' ''; return }
    $global:LASTEXITCODE = 0
    try {
        & $Action
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Add-Result $Step $Display 'FAIL' "exit code $LASTEXITCODE" $Fix }
        else                                          { Add-Result $Step $Display 'PASS' }
    } catch {
        Add-Result $Step $Display 'FAIL' $_.Exception.Message $Fix
    }
}
function Install-WingetPackage([string]$Id, [string]$Source = 'winget', [string]$Fix) {
    if (-not $Fix) {
        $url = $VendorUrls[$Id]
        $Fix = "Open an Administrator PowerShell and run:  winget install --id $Id --exact --source $Source  and read the message."
        $Fix += " Common causes: no internet or a proxy (check the browser works), or 'no applicable installer' (winget catalog lag)."
        if ($url) { $Fix += " If it still fails, download and install it from $url" }
    }
    Invoke-Cmd 'winget' "winget install --id $Id" -Fix $Fix {
        winget install --id $Id --exact --source $Source --accept-source-agreements --accept-package-agreements --no-upgrade --disable-interactivity
    }
}
function ConvertTo-HtmlText([string]$s) {
    if ($null -eq $s) { return '' }
    $s = $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
    # Turn bare URLs into links so the reader can click the vendor page.
    return [regex]::Replace($s, 'https?://[^\s)]+', { param($m) "<a href=`"$($m.Value)`">$($m.Value)</a>" })
}
function Write-Report {
    $counts = @{}
    foreach ($s in 'PASS','FAIL','SKIP','DRYRUN','MANUAL') { $counts[$s] = @($Results | Where-Object Status -eq $s).Count }
    $overall = if ($counts['FAIL'] -gt 0) { 'FAILED' } elseif ($DryRun) { 'DRY RUN' } else { 'PASSED' }
    $overallClass = if ($counts['FAIL'] -gt 0) { 'fail' } else { 'pass' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Laptop setup report</title>')
    [void]$sb.AppendLine('<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222;max-width:1200px}h1{margin:0 0 4px}.meta{color:#666;margin-bottom:16px}')
    [void]$sb.AppendLine('.badge{display:inline-block;padding:2px 10px;border-radius:12px;font-weight:600;font-size:13px}.pass{background:#d4edda;color:#155724}.fail{background:#f8d7da;color:#721c24}.skip{background:#e2e3e5;color:#383d41}.dryrun{background:#fff3cd;color:#856404}.manual{background:#cce5ff;color:#004085}')
    [void]$sb.AppendLine('.overall{font-size:20px;padding:6px 16px}table{border-collapse:collapse;width:100%;margin-top:12px}th,td{border:1px solid #ddd;padding:8px;vertical-align:top;text-align:left;font-size:14px}th{background:#f4f4f4}tr.fail td{background:#fff5f5}code{background:#f4f4f4;padding:1px 4px}')
    [void]$sb.AppendLine('h2{margin-top:28px;border-bottom:1px solid #ddd;padding-bottom:4px}.action{white-space:pre-wrap}</style></head><body>')
    [void]$sb.AppendLine("<h1>Laptop setup report</h1><div class=`"meta`">$env:COMPUTERNAME &middot; user $env:USERNAME &middot; $(Get-Date -Format 'yyyy-MM-dd HH:mm') &middot; duration $([int](New-TimeSpan $Started (Get-Date)).TotalMinutes) min &middot; admin=$IsAdmin</div>")
    $dry = if ($DryRun) { " <span class=`"badge dryrun`">$($counts['DRYRUN']) dry-run</span>" } else { '' }
    [void]$sb.AppendLine("<span class=`"badge overall $overallClass`">$overall</span> &nbsp; <span class=`"badge pass`">$($counts['PASS']) passed</span> <span class=`"badge fail`">$($counts['FAIL']) failed</span> <span class=`"badge skip`">$($counts['SKIP']) skipped</span> <span class=`"badge manual`">$($counts['MANUAL']) manual</span>$dry")
    if ($RebootNeeded) { [void]$sb.AppendLine('<p><b>Reboot required.</b> Restart Windows, then run the script again to finish WSL/Ubuntu.</p>') }

    $fails = @($Results | Where-Object Status -eq 'FAIL')
    if ($fails.Count -gt 0) {
        [void]$sb.AppendLine('<h2>Failed steps: what to do</h2><table><tr><th style="width:8%">Step</th><th style="width:27%">Item</th><th style="width:20%">Error</th><th>Action for you</th></tr>')
        foreach ($r in $fails) {
            [void]$sb.AppendLine("<tr class=`"fail`"><td>$(ConvertTo-HtmlText $r.Step)</td><td><code>$(ConvertTo-HtmlText $r.Item)</code></td><td>$(ConvertTo-HtmlText $r.Detail)</td><td class=`"action`">$(ConvertTo-HtmlText $r.Action)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }
    $skips = @($Results | Where-Object Status -eq 'SKIP')
    if ($skips.Count -gt 0) {
        [void]$sb.AppendLine('<h2>Skipped steps: what to do</h2><table><tr><th style="width:8%">Step</th><th style="width:27%">Item</th><th style="width:20%">Reason</th><th>Action for you</th></tr>')
        foreach ($r in $skips) {
            [void]$sb.AppendLine("<tr class=`"skip`"><td>$(ConvertTo-HtmlText $r.Step)</td><td><code>$(ConvertTo-HtmlText $r.Item)</code></td><td>$(ConvertTo-HtmlText $r.Detail)</td><td class=`"action`">$(ConvertTo-HtmlText $r.Action)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }
    $manual = @($Results | Where-Object Status -eq 'MANUAL')
    if ($manual.Count -gt 0) {
        [void]$sb.AppendLine('<h2>Manual checklist (licences, accounts, BitLocker)</h2><ol>')
        foreach ($r in $manual) { [void]$sb.AppendLine("<li>$(ConvertTo-HtmlText $r.Action)</li>") }
        [void]$sb.AppendLine('</ol>')
    }
    [void]$sb.AppendLine('<h2>All steps</h2><table><tr><th style="width:8%">Step</th><th style="width:32%">Item</th><th style="width:8%">Status</th><th>Detail</th></tr>')
    foreach ($r in ($Results | Where-Object Status -ne 'MANUAL')) {
        $cls = $r.Status.ToLower()
        [void]$sb.AppendLine("<tr class=`"$cls`"><td>$(ConvertTo-HtmlText $r.Step)</td><td><code>$(ConvertTo-HtmlText $r.Item)</code></td><td><span class=`"badge $cls`">$($r.Status)</span></td><td>$(ConvertTo-HtmlText $r.Detail)</td></tr>")
    }
    [void]$sb.AppendLine('</table>')
    [void]$sb.AppendLine("<p class=`"meta`">Rerunning the script is safe: installed items are skipped. Report written by setup-employee.ps1 to $(ConvertTo-HtmlText $ReportPath)</p></body></html>")
    try {
        Set-Content -Path $ReportPath -Value $sb.ToString() -Encoding UTF8
        Write-Host "`nReport: $ReportPath" -ForegroundColor Cyan
        if (-not $DryRun -and -not $NoOpen) { Start-Process $ReportPath -ErrorAction SilentlyContinue }
    } catch {
        Write-Host "Could not write report to $ReportPath ($($_.Exception.Message))" -ForegroundColor Red
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
    $fixFeature = 'Open "Turn Windows features on or off" (optionalfeatures.exe), tick "Windows Subsystem for Linux" and "Virtual Machine Platform", click OK and reboot. If they will not enable, check that virtualization (Intel VT-x / AMD-V, SVM) is turned on in the laptop BIOS/UEFI.'
    foreach ($feature in 'Microsoft-Windows-Subsystem-Linux','VirtualMachinePlatform') {
        if (-not $DryRun) {
            $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue).State
            if ($state -eq 'Enabled') { Write-Host "  $feature already enabled"; Add-Result 'features' $feature 'PASS' 'already enabled'; continue }
        }
        Invoke-Cmd 'features' "Enable-WindowsOptionalFeature $feature" -Fix $fixFeature {
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
        Add-Result 'winget' 'winget available' 'FAIL' 'winget.exe not found' 'Open the Microsoft Store, search "App Installer" and install/update it (or run Windows Update). Then rerun the script. Every application in this step still needs installing.'
    } else {
        foreach ($id in $WingetIds) { Install-WingetPackage $id }
        Install-WingetPackage $WhatsAppStoreId -Source msstore -Fix 'Open the Microsoft Store, search "WhatsApp" and click Install. (The Store source is often blocked by security software; this is expected and harmless.)'
        Update-SessionPath
    }
}

# ---------------------------------------------------------------- maven
if ($Steps -contains 'maven') {
    Write-Step 'maven: Apache Maven via Chocolatey (not available in winget)'
    $fixMaven = 'Download the "Binary zip archive" for Maven 3.9.x from https://maven.apache.org/download.cgi, extract it to C:\maven3, then add C:\maven3\bin to the system PATH (System Properties > Environment Variables). Verify with:  mvn -v'
    if (-not (Test-Cmd choco)) {
        Invoke-Cmd 'maven' 'install Chocolatey from community.chocolatey.org/install.ps1' -Fix "Chocolatey could not be installed (usually no internet or a proxy). Either follow https://chocolatey.org/install by hand and rerun, or skip Chocolatey: $fixMaven" {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        Update-SessionPath
    }
    if ((Test-Cmd choco) -or $DryRun) {
        Invoke-Cmd 'maven' 'choco install maven -y' -Fix "Run  choco install maven -y  in an Administrator PowerShell and read the error. If it keeps failing: $fixMaven" { choco install maven -y --no-progress }
        Update-SessionPath
    } elseif (-not $DryRun) {
        Add-Result 'maven' 'choco install maven -y' 'SKIP' 'Chocolatey not available' $fixMaven
    }
}

# ---------------------------------------------------------------- java
if ($Steps -contains 'java') {
    Write-Step 'java: JAVA_HOME and PATH for JDK 25'
    $jdk = Get-ChildItem 'C:\Program Files\Java' -Directory -Filter 'jdk-25*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $jdk) {
        if ($DryRun) { $jdk = [pscustomobject]@{ FullName = 'C:\Program Files\Java\jdk-25' } }
        else { Add-Result 'java' 'find JDK 25 under C:\Program Files\Java' 'FAIL' 'no jdk-25* folder' 'JDK 25 is not installed. Fix the "winget install --id Oracle.JDK.25" failure first, then rerun the script so JAVA_HOME gets set. To set it by hand: System Properties > Environment Variables > New system variable JAVA_HOME = C:\Program Files\Java\jdk-25.x, and append %JAVA_HOME%\bin to the system Path.' }
    }
    if ($jdk) {
        Invoke-Cmd 'java' "set JAVA_HOME=$($jdk.FullName)" -Fix "Set it by hand: System Properties > Environment Variables > New system variable JAVA_HOME = $($jdk.FullName), and append %JAVA_HOME%\bin to the system Path. Verify in a new terminal with:  java -version" {
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
        Invoke-Cmd 'python' 'py install 3.11' -Fix 'Open a new PowerShell (so PATH is refreshed) and run:  py install 3.11  . If py is not recognised, sign out and back in first. Alternatively install Python 3.11 from https://www.python.org/downloads/windows/ and verify with:  py -3.11 --version' { py install 3.11 }
    } else {
        Add-Result 'python' 'py install 3.11' 'SKIP' 'Python Install Manager (py) not on PATH' 'Fix the "winget install --id Python.PythonInstallManager" failure, or sign out and back in so PATH refreshes, then rerun the script (or run  py install 3.11  yourself).'
    }
}

# ---------------------------------------------------------------- vscode
if ($Steps -contains 'vscode') {
    Write-Step 'vscode: extensions'
    Update-SessionPath
    if ((Test-Cmd code) -or $DryRun) {
        foreach ($ext in $VsCodeExtensions) {
            Invoke-Cmd 'vscode' "code --install-extension $ext" -Fix "Open VS Code, press Ctrl+Shift+X, search for '$ext' and click Install. (Or in a new terminal run:  code --install-extension $ext )" { code --install-extension $ext --force }
        }
    } else {
        Add-Result 'vscode' 'code --install-extension (8 extensions)' 'SKIP' 'VS Code "code" CLI not on PATH' "Fix the 'winget install --id Microsoft.VisualStudioCode' failure, or sign out and back in so PATH refreshes, then rerun the script. Or open VS Code, press Ctrl+Shift+X and install: $($VsCodeExtensions -join ', ')"
    }
}

# ---------------------------------------------------------------- msys2
if ($Steps -contains 'msys2') {
    Write-Step 'msys2: gcc, make, autotools, pkgconf'
    $bash = 'C:\msys64\usr\bin\bash.exe'
    $fixMsys = "Open 'MSYS2 MSYS' from the Start menu and run:  pacman -Syu --noconfirm  (twice if the window closes), then:  pacman -S --needed --noconfirm $($Msys2Packages -join ' ')"
    if ((Test-Path $bash) -or $DryRun) {
        # First update may replace core packages and end the shell; running twice is the documented pattern.
        Invoke-Cmd 'msys2' 'pacman -Syu --noconfirm (core update, pass 1)' -Fix $fixMsys { & $bash -lc 'pacman -Syu --noconfirm' }
        Invoke-Cmd 'msys2' 'pacman -Syu --noconfirm (pass 2)'              -Fix $fixMsys { & $bash -lc 'pacman -Syu --noconfirm' }
        Invoke-Cmd 'msys2' "pacman -S --needed --noconfirm $($Msys2Packages -join ' ')" -Fix $fixMsys {
            & $bash -lc "pacman -S --needed --noconfirm $($Msys2Packages -join ' ')"
        }
    } else {
        Add-Result 'msys2' 'pacman packages' 'SKIP' 'MSYS2 not found at C:\msys64' "Fix the 'winget install --id MSYS2.MSYS2' failure (or install from https://www.msys2.org/), then rerun the script. Or by hand: $fixMsys"
    }
}

# ---------------------------------------------------------------- wsl
if ($Steps -contains 'wsl') {
    Write-Step "wsl: $UbuntuDistro"
    $fixWsl = "After a reboot, open an Administrator PowerShell and run:  wsl --install -d $UbuntuDistro  . If it reports a virtualization error, enable Intel VT-x / AMD-V (SVM) in the BIOS/UEFI. If the download fails, run:  wsl --update  and retry."
    if ($RebootNeeded -and -not $DryRun) {
        Add-Result 'wsl' "wsl --install -d $UbuntuDistro" 'SKIP' 'Windows features were just enabled; reboot first' 'Reboot Windows, then run this script again. It will install Ubuntu on the second run.'
        Write-Note 'Windows features were just enabled. Reboot, then rerun this script to install Ubuntu.'
    } elseif (-not (Test-Cmd wsl)) {
        Add-Result 'wsl' "wsl --install -d $UbuntuDistro" 'FAIL' 'wsl.exe not found' "Windows Subsystem for Linux is not enabled. Fix the 'features' step, reboot, then rerun. $fixWsl"
    } else {
        $distros = ((wsl --list --quiet 2>$null) | Out-String) -replace "`0", ''
        if ($distros -match "(?m)^$([regex]::Escape($UbuntuDistro))\s*$") {
            Write-Host "  $UbuntuDistro already installed"
            Add-Result 'wsl' "wsl --install -d $UbuntuDistro" 'PASS' 'already installed'
        } else {
            Invoke-Cmd 'wsl' "wsl --install -d $UbuntuDistro --no-launch" -Fix $fixWsl { wsl --install -d $UbuntuDistro --no-launch }
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
        Add-Result 'wslconfig' $cfg 'PASS' 'already exists; left unchanged'
    } else {
        Invoke-Cmd 'wslconfig' "write $cfg (memory=6GB processors=4 swap=2GB)" -Fix "Create the file $cfg in Notepad with these four lines:`n[wsl2]`nmemory=6GB`nprocessors=4`nswap=2GB" { Set-Content -Path $cfg -Value $WslConfig -Encoding ASCII }
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
        'Windows Update: install all pending updates. Afterwards run update-employee.ps1 monthly to keep the tools current.'
    )
    $i = 1
    foreach ($item in $items) {
        Write-Host ("  {0,2}. {1}" -f $i, $item)
        Add-Result 'checklist' "manual item $i" 'MANUAL' '' $item
        $i++
    }
    if ($RebootNeeded) { Write-Host "`n  REBOOT NOW, then run this script again to finish WSL/Ubuntu." -ForegroundColor Magenta }
}

# ---------------------------------------------------------------- summary + report
Write-Host ''
$failed = @($Results | Where-Object Status -eq 'FAIL')
if ($failed.Count -eq 0) {
    Write-Host 'setup-employee finished with no failures.' -ForegroundColor Green
} else {
    Write-Host "setup-employee finished with $($failed.Count) failure(s):" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - [$($_.Step)] $($_.Item): $($_.Detail)" }
    Write-Host '  See the HTML report for what to do about each one.'
}
Write-Report
if ($failed.Count -gt 0 -and $RunAsFile) { exit 1 }
