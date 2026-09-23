# Notes: things to fix or codify later

Companion to [`INVENTORY.md`](INVENTORY.md). Nothing here has been changed; these are observations from the 2026-09-18 snapshot.

## Conflicts and stale entries

- **Six Java installs** across `C:\Java*`, `Program Files\Java`, and `.jdks`. Only Java 25 is on PATH.
- **Duplicates:** Copilot CLI (winget + npm), VS Code (User + MSIX), gh (winget + choco), Notepad++ and WinMerge (installer + MSIX).
- **Dead PATH entries:** `C:\Python313` (machine PATH) and `C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2024.2.5\bin` (user PATH). Neither directory exists.
- **Unmanaged installs:** Maven, Terraform, and all `C:\Java*` directories were hand-extracted and are not tracked by winget or choco.
- **.NET** has runtime 7.0 only, no SDK, so `dotnet build` will not work.
- **Updates pending (winget):** Git 2.55, Docker Desktop 4.91, IntelliJ 2026.2.2, AWS CLI 2.36, gh 2.101, Antigravity 2.14, cloudflared 2026.9, Terraform not tracked.
- Chocolatey reports a pending reboot.

## Security observations

- Two antivirus engines registered; Defender is off because Norton is primary. Normal, but the
  machine depends on the Norton subscription staying active.
- Two VPN products (Surfshark + Norton VPN). Only one should be routing at a time.
- Office 2007 is out of support since 2017 and receives no security updates.



## Unmanaged installs to codify

These were installed by hand (zip extract or MSI) and no package manager tracks them. Record the
source URL and version here or move them under winget/choco so a rebuild is reproducible.

| Item | Path | Version | Suggested winget/choco ID |
|---|---|---|---|
| Oracle JDK 25 | `C:\Java25` | 25.0.3 | `Oracle.JDK.25` |
| OpenJDK 21 | `C:\Java21` | 21.0.9 | `Microsoft.OpenJDK.21` or `EclipseAdoptium.Temurin.21.JDK` |
| OpenJDK 17 | `C:\Java17` | 17.0.14 | `Microsoft.OpenJDK.17` or `EclipseAdoptium.Temurin.17.JDK` |
| OpenJDK 23 | `C:\Java` | 23.0.1 | probably removable (non-LTS) |
| Apache Maven | `C:\maven3` | 3.9.11 | `Apache.Maven` |
| Terraform | `C:\terraform_1.15.5_windows_amd64` | 1.15.5 | `Hashicorp.Terraform` |
| Node.js | `C:\Program Files\nodejs` | 24.12.0 | `OpenJS.NodeJS.LTS` |
| Postman | user profile | 12.28.6 | `Postman.Postman` |
| MSYS2 | `C:\msys64` | 20251213 | `MSYS2.MSYS2` |

## Possible follow-ups (not done)

- Bootstrap script (`winget import exports/winget-dev.json`, `choco install exports/choco-packages.config`, npm/pip/uv installs).
- Remove dead PATH entries and duplicate installs listed above.
- Decide on a single JDK layout (for example only `.jdks` managed by IntelliJ, or only winget-managed JDKs).
- Install a .NET SDK if any .NET project work is expected.

## Employee laptop scripts

`employee-laptop/` holds the clean install for new employee laptops (`setup-employee.ps1`),
the version-check/update companion (`update-employee.ps1`) and a `README.md` with run
instructions. Both follow `SOFTWARE_LIST_curated.md` (winget for everything, Chocolatey only
for Maven, JDK 25 only, eight VS Code extensions, `.wslconfig` cap) and write an HTML
pass/fail report on the Desktop with an action for every failure. They are published as a
public Gist so a vendor can fetch them without repo access:
https://gist.github.com/sahebray85/5ee0da6bf8c918f0ff94af6d58199040
After editing, push with `gh gist edit 5ee0da6bf8c918f0ff94af6d58199040 -f <name>.ps1 employee-laptop/<name>.ps1`.
Keep them free of company names, account details and local paths. `bootstrap.ps1` remains the
replay of the owner's own machine and is not for employees.

## Laptop quotation evaluation

`QUOTE_EVALUATION_2026-09-23.md` evaluates Genius Infoway quotation GIB/247/2026-27 (PDF kept
untracked in the repo root because it carries the vendor's bank details) against
`HARDWARE_REQUIREMENT.md` and Indian retail prices. Short version: nothing quoted matches the
spec, the P16s is 25% over reseller price, and both refurbished lines fail the 1-year warranty
requirement.
