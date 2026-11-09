# wsl-toolkit scripts

What every script reads, deletes or changes, and all its options.

![Diagram. wsl-space-scan.sh finds the paths to pass to wsl-deep-clean.sh. docker-list-images.sh shows which images docker-cleanup.sh will remove. Both cleanup scripts end with fstrim -av. After wsl --shutdown, compact.ps1 runs diskpart, and ext4.vhdx gets smaller on C:.](media/diagram.png)

The scripts are independent. The diagram shows the order they are meant to run in.

## Find

| Script | What it reads |
| --- | --- |
| `disk/wsl-space-scan.sh` | `df -h /`. Directories over 500 MB in `/` and over 200 MB in `/var` and `$HOME`. Sizes of apt, journal, snap, npm, pnpm, cargo, rustup, pip, uv, yarn, bun, deno, gradle, maven, `/tmp` and `/var/tmp`. The 20 largest `node_modules` trees and the 30 largest `target`, `dist`, `build`, `.next`, `.turbo`, `.venv`, `venv` and `__pycache__` trees over 200 MB under `$HOME`. |
| `docker/docker-list-images.sh` | Images used by any container, running or stopped, and the idle images that `docker image prune -af` would delete. |

## Delete inside Linux

| Command | What it deletes |
| --- | --- |
| `disk/wsl-deep-clean.sh --clean [PATH ...]` | Each `PATH` (`rm -rf`), then runs `pnpm store prune`, `npm cache clean --force`, `~/.bun/install/cache`, `uv cache clean` (or `~/.cache/uv`), `sudo apt clean` and `journalctl --vacuum-size=200M`. Ends with `sudo fstrim -av` and prints the GiB freed. |
| `docker/docker-audit.sh --prune` | Dangling build cache only (`docker builder prune -f`). Then lists every container, volume and volume size. |
| `docker/docker-cleanup.sh --prune` | All images that no container uses (`docker image prune -af`) and anonymous volumes (64-character hex names) that no container uses. Named volumes are kept. Ends with `fstrim -av`. |
| `docker/docker-final.sh --prune` | The containers in `REMOVE_CONTAINERS` and the images in `REMOVE_IMAGES`, then unused images and build cache. Ends with `fstrim -av`. |

`docker-cleanup.sh` and `docker-final.sh` run `sudo systemctl start docker` first.

## Shrink the VHD from Windows

Run these in Windows PowerShell, not in WSL. Each one runs `wsl.exe --shutdown` first, which stops every distro.

| Script | What it does |
| --- | --- |
| `disk/compact.ps1 -VhdPath <ext4.vhdx>` | Writes a diskpart script that attaches the VHD read-only, runs `compact vdisk` and detaches it. Logs the size before and after and the free space on `C:` to `%TEMP%\compact.log`. |
| `disk/compact-run.ps1 -VhdPath <ext4.vhdx> -DiskpartScript <file> -Distro <name>` | Dismounts the VHD if it is attached, runs `wsl --manage <name> --set-sparse true`, shuts WSL down again, and runs your diskpart script. |
| `disk/fix-disk.ps1 -VhdPath <ext4.vhdx> -PagefileInitialMB <MB> -PagefileMaximumMB <MB> -Apply` | Needs an elevated terminal. Deletes `C:\Windows\Logs\CBS` files, turns hibernation off (`powercfg /h off`), sets a fixed pagefile size, and compacts the VHD. Without `-Apply` it stops and changes nothing. The pagefile change takes effect after a reboot. |

## Manage WSL

| Script | What it does |
| --- | --- |
| `wsl/wsl-shutdown.ps1 [-ClaudePath <exe>]` | Waits 30 seconds, then asks the Claude Code CLI in print mode, limited to `wsl` commands, to run `wsl --shutdown` and `wsl --list --running`. Logs to `%TEMP%\wsl-shutdown.log`. |
| `wsl/restart.ps1 -Distro <name> -AppPath <exe> -ProcessName <name>` | Waits 25 seconds, starts the distro, stops the named Windows process, and starts the app again. |
| `wsl/kill-watcher.ps1 -CommandLinePattern <regex>` | Stops every `powershell.exe` whose command line matches the pattern. |
| `wsl/wsl-defender-exclusions.ps1 -Paths <path>,...` | Needs an elevated terminal. Adds Microsoft Defender exclusions for the paths and for `wsl.exe`, `wslservice.exe`, `wslhost.exe`, `vmmemWSL`, `docker.exe` and `dockerd.exe`, then lists all exclusions. It does not turn off real-time protection. |

## Route traffic through a VPN

`homelab-routing/` runs the `qmcgaw/gluetun` container with your WireGuard config and an HTTP proxy on port 8888.

```bash
cd homelab-routing
mkdir -p wireguard && cp <your-provider>.conf wireguard/wg0.conf
./menu.sh start    # copies config.example.env to .env if missing, then docker compose up -d
./menu.sh test     # your direct IP, then your IP through http://127.0.0.1:8888
./menu.sh stop
```

`menu.sh` also accepts `status` (the default) and `logs`. `scripts/start.sh`, `scripts/stop.sh` and `scripts/test.sh` do the same as `start`, `stop` and `test`.

## Configuration

| Name | Used by | Default | What it does |
| --- | --- | --- | --- |
| `PATH ...` arguments | `wsl-deep-clean.sh` | none | Paths to delete before the caches are cleared. |
| `REMOVE_CONTAINERS` | `docker-final.sh` | empty | Space-separated container names to remove. |
| `REMOVE_IMAGES` | `docker-final.sh` | empty | Space-separated images to remove. |
| `-VhdPath` | `compact.ps1`, `compact-run.ps1`, `fix-disk.ps1` | required | Windows path of the distro's `ext4.vhdx`. |
| `-DiskpartScript` | `compact-run.ps1` | required | diskpart script that selects and compacts your VHD. |
| `-Distro` | `compact-run.ps1`, `restart.ps1` | required | WSL distro name. |
| `-PagefileInitialMB`, `-PagefileMaximumMB` | `fix-disk.ps1` | required | Fixed pagefile size. |
| `-Apply` | `fix-disk.ps1` | off | Required before the script changes anything. |
| `-LogPath` | `compact.ps1`, `compact-run.ps1`, `fix-disk.ps1`, `restart.ps1`, `wsl-shutdown.ps1` | a file in `%TEMP%` | Log file. |
| `-ClaudePath` | `wsl-shutdown.ps1` | `claude.exe` | Claude Code CLI to call. |
| `-AppPath`, `-ProcessName` | `restart.ps1` | required | App to start again and the process to stop first. |
| `-CommandLinePattern` | `kill-watcher.ps1` | required | Regular expression matched against `powershell.exe` command lines. |
| `-Paths` | `wsl-defender-exclusions.ps1` | required | Folders to exclude from Defender scans. |
| `homelab-routing/.env` | `compose.yml` | copied from `config.example.env` | gluetun settings: `VPN_SERVICE_PROVIDER=custom`, `VPN_TYPE=wireguard`, `HTTPPROXY=on` on `:8888`, `DOT=on`, `BLOCK_MALICIOUS=on`. |
| `homelab-routing/wireguard/wg0.conf` | `compose.yml` | none | Your VPN provider's WireGuard config, mounted read-only. |

`.env`, `*.log`, `homelab-routing/wireguard/` and `homelab-routing/gluetun/` are git-ignored.
