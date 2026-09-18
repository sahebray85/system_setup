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
