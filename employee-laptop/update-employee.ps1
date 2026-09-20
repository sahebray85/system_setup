#Requires -Version 5.1
<#
.SYNOPSIS
    Check the developer laptop for newer versions of the installed tools, and optionally install them.

.DESCRIPTION
    Companion to setup-employee.ps1. Without -Install it only checks and writes an HTML report
    (update-employee-report.html on the Desktop) listing every tool as UP-TO-DATE, UPDATE
    AVAILABLE or UNKNOWN, with the exact command to install each update. With -Install it applies
    the updates and reports UPDATED or FAILED with an action for every failure.

    What it checks:
      winget   every application installed by setup-employee.ps1 (winget upgrade)
      choco    Apache Maven (choco outdated)
      vscode   VS Code extensions (code --update-extensions)
      wsl      WSL kernel/runtime (wsl --update) and Ubuntu packages (apt)
      msys2    MSYS2 packages (pacman -Qu / -Syu)
      windows  reminder to run Windows Update (Settings)

    HOW TO RUN (Administrator PowerShell, as the employee's own account):
        powershell -ExecutionPolicy Bypass -File .\update-employee.ps1            # check only
        powershell -ExecutionPolicy Bypass -File .\update-employee.ps1 -Install   # check and install

    Or download and run in one line:
        irm https://gist.githubusercontent.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040/raw/update-employee.ps1 -OutFile update-employee.ps1; powershell -ExecutionPolicy Bypass -File .\update-employee.ps1

.PARAMETER Install
    Install the available updates instead of only reporting them.
.PARAMETER Only
    Check only these areas: winget, choco, vscode, wsl, msys2, windows.
.PARAMETER Skip
    Check everything except these areas.
.PARAMETER NoOpen
    Do not open the HTML report in the browser when finished.
.PARAMETER ReportPath
    Where to write the HTML report. Default: <Desktop>\update-employee-report.html
#>
[CmdletBinding()]
param(
    [switch]$Install,
    [ValidateSet('winget','choco','vscode','wsl','msys2','windows')][string[]]$Only,
    [ValidateSet('winget','choco','vscode','wsl','msys2','windows')][string[]]$Skip = @(),
    [string]$ReportPath,
    [switch]$NoOpen
)

$ErrorActionPreference = 'Continue'
$AllAreas = 'winget','choco','vscode','wsl','msys2','windows'
$Areas    = if ($Only) { $Only } else { $AllAreas }
$Areas    = @($Areas | Where-Object { $Skip -notcontains $_ })
$IsAdmin  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
$Results  = New-Object System.Collections.Generic.List[object]
$RunAsFile = [bool]$MyInvocation.MyCommand.Path
$Started  = Get-Date
if (-not $ReportPath) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) { $desktop = $env:USERPROFILE }
    $ReportPath = Join-Path $desktop 'update-employee-report.html'
}

# Same list as setup-employee.ps1. Only these are upgraded with -Install; anything else winget
# reports is listed as "available, not managed" so nothing unexpected changes.
$WingetIds = @(
    '7zip.7zip', 'Surfshark.Surfshark',
    'JetBrains.IntelliJIDEA', 'Microsoft.VisualStudioCode', 'Notepad++.Notepad++',
    'DBeaver.DBeaver.Community', 'Postman.Postman', 'WinMerge.WinMerge',
    'Oracle.JDK.25', 'OpenJS.NodeJS.LTS', 'Python.PythonInstallManager', 'astral-sh.uv',
    'Microsoft.PowerShell', 'MSYS2.MSYS2',
    'Git.Git', 'GitHub.GitLFS', 'GitHub.cli',
    'Docker.DockerDesktop', 'Microsoft.WSL', 'Amazon.AWSCLI', 'Hashicorp.Terraform',
    'Anthropic.Claude', 'Anthropic.ClaudeCode', 'GitHub.Copilot', 'OpenAI.Codex',
    'jqlang.jq', 'Gyan.FFmpeg',
    'Microsoft.Office', 'Microsoft.Teams', 'Zoom.Zoom', 'Adobe.Acrobat.Reader.64-bit'
)
$UbuntuDistro = 'Ubuntu-24.04'

# ---------------------------------------------------------------- helpers
function Write-Step([string]$Name) { Write-Host "`n=== $Name ===" -ForegroundColor Cyan }
function Write-Note([string]$Text) { Write-Host "  $Text" -ForegroundColor Yellow }
function Test-Cmd([string]$Name)   { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Add-Result {
    # Status: UP-TO-DATE, AVAILABLE (update exists, not installed), UPDATED, FAILED, UNKNOWN (could not check), MANUAL
    param([string]$Area, [string]$Item, [string]$Installed, [string]$Available,
          [ValidateSet('UP-TO-DATE','AVAILABLE','UPDATED','FAILED','UNKNOWN','MANUAL')][string]$Status,
          [string]$Detail = '', [string]$Action = '')
    $Results.Add([pscustomobject]@{ Area=$Area; Item=$Item; Installed=$Installed; Available=$Available; Status=$Status; Detail=$Detail; Action=$Action })
    $colour = switch ($Status) { 'UP-TO-DATE' {'Green'} 'UPDATED' {'Green'} 'AVAILABLE' {'Yellow'} 'FAILED' {'Red'} default {'Gray'} }
    Write-Host ("  {0,-12} {1}  {2}" -f $Status, $Item, $(if ($Available) { "$Installed -> $Available" } else { $Detail })) -ForegroundColor $colour
}
function Invoke-Update {
    # Runs $Action and returns $true on success. Records FAILED with $Fix on error.
    param([string]$Area, [string]$Item, [string]$Installed, [string]$Available, [scriptblock]$Action, [string]$Fix)
    $global:LASTEXITCODE = 0
    try {
        & $Action
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Add-Result $Area $Item $Installed $Available 'FAILED' "exit code $LASTEXITCODE" $Fix; return $false }
        Add-Result $Area $Item $Installed $Available 'UPDATED'
        return $true
    } catch {
        Add-Result $Area $Item $Installed $Available 'FAILED' $_.Exception.Message $Fix
        return $false
    }
}
function ConvertTo-HtmlText([string]$s) {
    if ($null -eq $s) { return '' }
    $s = $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
    return [regex]::Replace($s, 'https?://[^\s)]+', { param($m) "<a href=`"$($m.Value)`">$($m.Value)</a>" })
}
function Get-WingetUpgrades {
    # Parses the fixed-width table printed by "winget upgrade". Returns objects with Id, Version, Available.
    $raw = (winget upgrade --include-unknown --accept-source-agreements --disable-interactivity 2>$null) | Out-String
    $lines = $raw -split "`r?`n" | Where-Object { $_.Trim() }
    $header = $lines | Where-Object { $_ -match '^\s*Name\s+Id\s+Version\s+Available' } | Select-Object -First 1
    if (-not $header) { return @() }
    $idCol = $header.IndexOf('Id'); $verCol = $header.IndexOf('Version'); $avCol = $header.IndexOf('Available'); $srcCol = $header.IndexOf('Source')
    if ($srcCol -lt 0) { $srcCol = $header.Length }
    $out = @()
    $started = $false
    foreach ($l in $lines) {
        if ($l -eq $header) { $started = $true; continue }
        if (-not $started -or $l -match '^-+$' -or $l -match 'upgrades? available' -or $l.Length -lt $avCol) { continue }
        $id  = $l.Substring($idCol,  [Math]::Min($verCol - $idCol, $l.Length - $idCol)).Trim()
        $ver = $l.Substring($verCol, [Math]::Min($avCol - $verCol, $l.Length - $verCol)).Trim()
        $av  = $l.Substring($avCol,  [Math]::Min($srcCol - $avCol, $l.Length - $avCol)).Trim()
        if ($id -and $av) { $out += [pscustomobject]@{ Id = $id; Version = $ver; Available = $av } }
    }
    return $out
}
function Write-Report {
    $counts = @{}
    foreach ($s in 'UP-TO-DATE','AVAILABLE','UPDATED','FAILED','UNKNOWN','MANUAL') { $counts[$s] = @($Results | Where-Object Status -eq $s).Count }
    $overall = if ($counts['FAILED'] -gt 0) { 'FAILED' } elseif ($counts['AVAILABLE'] -gt 0) { 'UPDATES AVAILABLE' } else { 'UP TO DATE' }
    $overallClass = if ($counts['FAILED'] -gt 0) { 'failed' } elseif ($counts['AVAILABLE'] -gt 0) { 'available' } else { 'up-to-date' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Laptop update report</title>')
    [void]$sb.AppendLine('<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222;max-width:1200px}h1{margin:0 0 4px}.meta{color:#666;margin-bottom:16px}')
    [void]$sb.AppendLine('.badge{display:inline-block;padding:2px 10px;border-radius:12px;font-weight:600;font-size:13px}.up-to-date,.updated{background:#d4edda;color:#155724}.failed{background:#f8d7da;color:#721c24}.available{background:#fff3cd;color:#856404}.unknown{background:#e2e3e5;color:#383d41}.manual{background:#cce5ff;color:#004085}')
    [void]$sb.AppendLine('.overall{font-size:20px;padding:6px 16px}table{border-collapse:collapse;width:100%;margin-top:12px}th,td{border:1px solid #ddd;padding:8px;vertical-align:top;text-align:left;font-size:14px}th{background:#f4f4f4}tr.failed td{background:#fff5f5}tr.available td{background:#fffdf3}code{background:#f4f4f4;padding:1px 4px}')
    [void]$sb.AppendLine('h2{margin-top:28px;border-bottom:1px solid #ddd;padding-bottom:4px}.action{white-space:pre-wrap}</style></head><body>')
    [void]$sb.AppendLine("<h1>Laptop update report</h1><div class=`"meta`">$env:COMPUTERNAME &middot; user $env:USERNAME &middot; $(Get-Date -Format 'yyyy-MM-dd HH:mm') &middot; mode: $(if ($Install) { 'check and install' } else { 'check only' }) &middot; duration $([int](New-TimeSpan $Started (Get-Date)).TotalMinutes) min</div>")
    [void]$sb.AppendLine("<span class=`"badge overall $overallClass`">$overall</span> &nbsp; <span class=`"badge up-to-date`">$($counts['UP-TO-DATE']) up to date</span> <span class=`"badge available`">$($counts['AVAILABLE']) available</span> <span class=`"badge updated`">$($counts['UPDATED']) updated</span> <span class=`"badge failed`">$($counts['FAILED']) failed</span> <span class=`"badge unknown`">$($counts['UNKNOWN']) unknown</span>")

    foreach ($section in @(
        @{ Status='FAILED';    Title='Failed updates: what to do';            Col='Error' },
        @{ Status='AVAILABLE'; Title='Updates available: how to install them'; Col='Detail' },
        @{ Status='UNKNOWN';   Title='Could not check: what to do';           Col='Reason' },
        @{ Status='MANUAL';    Title='Manual checks';                          Col='Detail' })) {
        $rows = @($Results | Where-Object Status -eq $section.Status)
        if ($rows.Count -eq 0) { continue }
        [void]$sb.AppendLine("<h2>$($section.Title)</h2><table><tr><th style=`"width:7%`">Area</th><th style=`"width:22%`">Item</th><th style=`"width:9%`">Installed</th><th style=`"width:9%`">Available</th><th style=`"width:15%`">$($section.Col)</th><th>Action for you</th></tr>")
        foreach ($r in $rows) {
            [void]$sb.AppendLine("<tr class=`"$($r.Status.ToLower())`"><td>$(ConvertTo-HtmlText $r.Area)</td><td><code>$(ConvertTo-HtmlText $r.Item)</code></td><td>$(ConvertTo-HtmlText $r.Installed)</td><td>$(ConvertTo-HtmlText $r.Available)</td><td>$(ConvertTo-HtmlText $r.Detail)</td><td class=`"action`">$(ConvertTo-HtmlText $r.Action)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')
    }
    [void]$sb.AppendLine('<h2>Everything checked</h2><table><tr><th style="width:7%">Area</th><th style="width:28%">Item</th><th style="width:12%">Status</th><th style="width:10%">Installed</th><th style="width:10%">Available</th><th>Detail</th></tr>')
    foreach ($r in $Results) {
        $cls = $r.Status.ToLower()
        [void]$sb.AppendLine("<tr class=`"$cls`"><td>$(ConvertTo-HtmlText $r.Area)</td><td><code>$(ConvertTo-HtmlText $r.Item)</code></td><td><span class=`"badge $cls`">$($r.Status)</span></td><td>$(ConvertTo-HtmlText $r.Installed)</td><td>$(ConvertTo-HtmlText $r.Available)</td><td>$(ConvertTo-HtmlText $r.Detail)</td></tr>")
    }
    [void]$sb.AppendLine('</table>')
    [void]$sb.AppendLine("<p class=`"meta`">To install everything listed as available in one go, run:  <code>powershell -ExecutionPolicy Bypass -File .\update-employee.ps1 -Install</code>  in an Administrator PowerShell. Report written by update-employee.ps1 to $(ConvertTo-HtmlText $ReportPath)</p></body></html>")
    try {
        Set-Content -Path $ReportPath -Value $sb.ToString() -Encoding UTF8
        Write-Host "`nReport: $ReportPath" -ForegroundColor Cyan
        if (-not $NoOpen) { Start-Process $ReportPath -ErrorAction SilentlyContinue }
    } catch {
        Write-Host "Could not write report to $ReportPath ($($_.Exception.Message))" -ForegroundColor Red
    }
}

Write-Host "update-employee.ps1  admin=$IsAdmin  install=$Install"
Write-Host "areas: $($Areas -join ', ')"
if ($Install -and -not $IsAdmin) {
    Write-Host '-Install needs an elevated (Administrator) PowerShell. Right-click PowerShell, "Run as administrator", then rerun.' -ForegroundColor Red
    return
}

# ---------------------------------------------------------------- winget
if ($Areas -contains 'winget') {
    Write-Step 'winget: applications'
    if (-not (Test-Cmd winget)) {
        Add-Result 'winget' 'winget' '' '' 'UNKNOWN' 'winget.exe not found' 'Open the Microsoft Store, search "App Installer" and install/update it, then rerun.'
    } else {
        Write-Host '  > winget upgrade (this takes a minute)'
        $upgrades = @(Get-WingetUpgrades)
        $managedUp = @($upgrades | Where-Object { $WingetIds -contains $_.Id })
        foreach ($id in $WingetIds) {
            $u = $managedUp | Where-Object Id -eq $id | Select-Object -First 1
            if (-not $u) { Add-Result 'winget' $id '' '' 'UP-TO-DATE' 'no newer version listed by winget'; continue }
            $cmd = "winget upgrade --id $id --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity"
            if ($Install) {
                $null = Invoke-Update 'winget' $id $u.Version $u.Available -Fix "Run in an Administrator PowerShell:  $cmd  and read the message. If the app is open, close it and retry. If winget says the installer hash mismatched, wait a day (catalog lag) or install from the vendor site." { winget upgrade --id $id --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity }
            } else {
                Add-Result 'winget' $id $u.Version $u.Available 'AVAILABLE' 'newer version in winget' "Run in an Administrator PowerShell:  $cmd   (or rerun this script with -Install)"
            }
        }
        $other = @($upgrades | Where-Object { $WingetIds -notcontains $_.Id })
        foreach ($u in $other) {
            Add-Result 'winget' $u.Id $u.Version $u.Available 'MANUAL' 'not managed by setup-employee.ps1; left alone' "Optional. To update it run:  winget upgrade --id $($u.Id) --exact --source winget"
        }
    }
}

# ---------------------------------------------------------------- choco (Maven)
if ($Areas -contains 'choco') {
    Write-Step 'choco: Apache Maven'
    if (-not (Test-Cmd choco)) {
        Add-Result 'choco' 'maven' '' '' 'UNKNOWN' 'Chocolatey not installed' 'If Maven was installed by hand, compare  mvn -v  with the latest 3.9.x at https://maven.apache.org/download.cgi and replace the C:\maven3 folder if newer.'
    } else {
        Write-Host '  > choco outdated'
        $outdated = @(choco outdated -r --no-color 2>$null | Where-Object { $_ -match '^maven\|' })
        if ($outdated.Count -eq 0) {
            Add-Result 'choco' 'maven' '' '' 'UP-TO-DATE' 'choco outdated lists no newer maven'
        } else {
            $parts = $outdated[0] -split '\|'
            if ($Install) {
                $null = Invoke-Update 'choco' 'maven' $parts[1] $parts[2] -Fix 'Run in an Administrator PowerShell:  choco upgrade maven -y  and read the error. Fallback: download the latest 3.9.x zip from https://maven.apache.org/download.cgi and replace the C:\maven3 folder.' { choco upgrade maven -y --no-progress }
            } else {
                Add-Result 'choco' 'maven' $parts[1] $parts[2] 'AVAILABLE' 'newer version in Chocolatey' 'Run in an Administrator PowerShell:  choco upgrade maven -y   (or rerun this script with -Install)'
            }
        }
    }
}

# ---------------------------------------------------------------- vscode extensions
if ($Areas -contains 'vscode') {
    Write-Step 'vscode: extensions'
    if (-not (Test-Cmd code)) {
        Add-Result 'vscode' 'extensions' '' '' 'UNKNOWN' 'VS Code "code" CLI not on PATH' 'Open VS Code, press Ctrl+Shift+X and click "Update All" if shown.'
    } else {
        # The CLI cannot list which extensions are outdated, but it can update them all in one call.
        if ($Install) {
            $null = Invoke-Update 'vscode' 'code --update-extensions' '' '' -Fix 'Open VS Code, press Ctrl+Shift+X and click the "Update All" button, or run  code --update-extensions  in a terminal. If the error mentions "unable to verify the first certificate", a security product is inspecting TLS: open VS Code itself (it uses the Windows certificate store) and update from the Extensions view.' { code --update-extensions }
        } else {
            $n = @(code --list-extensions 2>$null).Count
            Add-Result 'vscode' "extensions ($n installed)" '' '' 'MANUAL' 'VS Code updates extensions itself when it starts' 'To force it now run:  code --update-extensions   (or rerun this script with -Install). VS Code itself is updated through winget above.'
        }
    }
}

# ---------------------------------------------------------------- wsl
if ($Areas -contains 'wsl') {
    Write-Step 'wsl: kernel and Ubuntu packages'
    if (-not (Test-Cmd wsl)) {
        Add-Result 'wsl' 'wsl' '' '' 'UNKNOWN' 'wsl.exe not found' 'WSL is not installed; run setup-employee.ps1 first.'
    } else {
        if ($Install) {
            $null = Invoke-Update 'wsl' 'wsl --update' '' '' -Fix 'Run in an Administrator PowerShell:  wsl --update  . If it cannot download, update "Windows Subsystem for Linux" from the Microsoft Store or winget (Microsoft.WSL).' { wsl --update }
        } else {
            $ver = ((wsl --version 2>$null) | Out-String) -replace "`0", ''
            $wslVer = if ($ver -match 'WSL version:\s*([\d.]+)') { $Matches[1] } else { '' }
            Add-Result 'wsl' 'WSL runtime' $wslVer '' 'MANUAL' 'wsl cannot report a newer version without installing it' 'Run in an Administrator PowerShell:  wsl --update   (safe, installs the latest WSL). Or rerun this script with -Install.'
        }
        $distros = ((wsl --list --quiet 2>$null) | Out-String) -replace "`0", ''
        if ($distros -match "(?m)^$([regex]::Escape($UbuntuDistro))\s*$") {
            Write-Host "  > apt list --upgradable in $UbuntuDistro"
            $apt = (wsl -d $UbuntuDistro -e bash -lc 'sudo -n apt-get update -qq >/dev/null 2>&1; apt list --upgradable 2>/dev/null | grep -c upgradable' 2>$null | Out-String).Trim()
            if ($apt -match '^\d+$') {
                if ([int]$apt -eq 0) {
                    Add-Result 'wsl' "$UbuntuDistro packages" '' '' 'UP-TO-DATE' 'apt lists no upgradable packages (list may be stale if sudo needs a password)'
                } elseif ($Install) {
                    Add-Result 'wsl' "$UbuntuDistro packages" '' "$apt packages" 'MANUAL' 'apt upgrade needs the Linux user password' "Open '$UbuntuDistro' from the Start menu and run:  sudo apt-get update && sudo apt-get upgrade -y"
                } else {
                    Add-Result 'wsl' "$UbuntuDistro packages" '' "$apt packages" 'AVAILABLE' 'apt lists upgradable packages' "Open '$UbuntuDistro' from the Start menu and run:  sudo apt-get update && sudo apt-get upgrade -y"
                }
            } else {
                Add-Result 'wsl' "$UbuntuDistro packages" '' '' 'UNKNOWN' 'could not query apt (Ubuntu not initialised or not running)' "Open '$UbuntuDistro' from the Start menu (create the user if asked) and run:  sudo apt-get update && sudo apt-get upgrade -y"
            }
        } else {
            Add-Result 'wsl' $UbuntuDistro '' '' 'UNKNOWN' 'distro not installed' 'Run setup-employee.ps1 (after a reboot) to install Ubuntu.'
        }
    }
}

# ---------------------------------------------------------------- msys2
if ($Areas -contains 'msys2') {
    Write-Step 'msys2: packages'
    $bash = 'C:\msys64\usr\bin\bash.exe'
    $fixMsys = "Open 'MSYS2 MSYS' from the Start menu and run:  pacman -Syu --noconfirm  (twice if the window closes). If it reports SSL certificate errors from the mirrors, a security product is inspecting TLS: export the proxy root certificate to /etc/pki/ca-trust/source/anchors/ and run  update-ca-trust  inside MSYS2, or update MSYS2 on a network without inspection."
    if (-not (Test-Path $bash)) {
        Add-Result 'msys2' 'pacman' '' '' 'UNKNOWN' 'MSYS2 not found at C:\msys64' 'MSYS2 is not installed; run setup-employee.ps1 first.'
    } elseif ($Install) {
        $ok = Invoke-Update 'msys2' 'pacman -Syu (pass 1)' '' '' -Fix $fixMsys { & $bash -lc 'pacman -Syu --noconfirm' }
        if ($ok) { $null = Invoke-Update 'msys2' 'pacman -Syu (pass 2)' '' '' -Fix $fixMsys { & $bash -lc 'pacman -Syu --noconfirm' } }
    } else {
        Write-Host '  > pacman -Sy; pacman -Qu'
        $q = @(& $bash -lc 'pacman -Sy >/dev/null 2>&1; pacman -Qu 2>/dev/null' 2>$null | Where-Object { $_ })
        if ($LASTEXITCODE -ne 0 -and $q.Count -eq 0) {
            Add-Result 'msys2' 'packages' '' '' 'UP-TO-DATE' 'pacman -Qu lists nothing'
        } elseif ($q.Count -eq 0) {
            Add-Result 'msys2' 'packages' '' '' 'UP-TO-DATE' 'pacman -Qu lists nothing'
        } else {
            $detail = ($q | Select-Object -First 5 | ForEach-Object { $_.Trim() }) -join '; '
            Add-Result 'msys2' 'packages' '' "$($q.Count) packages" 'AVAILABLE' $detail "$fixMsys Or rerun this script with -Install."
        }
    }
}

# ---------------------------------------------------------------- windows
if ($Areas -contains 'windows') {
    Write-Step 'windows: Windows Update'
    Add-Result 'windows' 'Windows Update' '' '' 'MANUAL' 'this script does not install Windows updates' 'Open Settings > Windows Update (or run  start ms-settings:windowsupdate ), click "Check for updates", install everything and reboot if asked.'
}

# ---------------------------------------------------------------- summary + report
Write-Host ''
$avail  = @($Results | Where-Object Status -eq 'AVAILABLE').Count
$failed = @($Results | Where-Object Status -eq 'FAILED').Count
if ($failed -gt 0)   { Write-Host "update-employee finished with $failed failure(s). See the report for what to do." -ForegroundColor Red }
elseif ($avail -gt 0) { Write-Host "update-employee: $avail update(s) available. Rerun with -Install to apply them, or follow the report." -ForegroundColor Yellow }
else                  { Write-Host 'update-employee: everything checked is up to date.' -ForegroundColor Green }
Write-Report
if ($failed -gt 0 -and $RunAsFile) { exit 1 }
