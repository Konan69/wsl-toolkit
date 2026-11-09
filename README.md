# wsl-toolkit

Get your disk space back from WSL.

WSL 2 keeps each distro in an `ext4.vhdx` that grows when Linux writes and never shrinks when it deletes. Getting `C:` back takes three steps: delete in Linux, `fstrim`, then compact the VHD from Windows with WSL shut down. These scripts do each step and print sizes before and after. There are also Docker cleanups, WSL restart helpers, and a WireGuard VPN gateway container.

![Terminal running wsl-space-scan.sh. It lists home subdirectories over 200 MB, then node_modules trees and build directories over 200 MB, with the largest ones highlighted.](docs/media/hero.gif)

## Install

WSL 2, bash, `sudo` and `fstrim`. Windows PowerShell 5.1 for the `.ps1` scripts. Docker in WSL for `docker/` and `homelab-routing/`.

```bash
git clone <this-repo-url> wsl-toolkit && cd wsl-toolkit
```

## Use

In WSL:

```bash
disk/wsl-space-scan.sh                          # read-only: big dirs, caches, node_modules, build trees (slow)
disk/wsl-deep-clean.sh --clean ~/old-project    # delete paths, clear package caches, vacuum journal, fstrim
docker/docker-list-images.sh                    # which images a prune would remove
docker/docker-cleanup.sh --prune                # remove unused images and anonymous volumes, fstrim
```

Then in Windows PowerShell (each one runs `wsl --shutdown` first):

```powershell
disk\compact.ps1 -VhdPath C:\path\to\ext4.vhdx     # diskpart compact vdisk, logs size before and after
```

Anything that deletes needs its flag. Without it, it prints usage and exits 2:

```console
$ disk/wsl-deep-clean.sh
Usage: disk/wsl-deep-clean.sh --clean [PATH ...]
Deletes PATHs, clears package caches and vacuums the journal to 200M, then runs fstrim.
```

To send traffic through your VPN provider, put its WireGuard config in `homelab-routing/wireguard/wg0.conf` and run `homelab-routing/menu.sh start`, then `test`. It runs gluetun with an HTTP proxy on port 8888.

Every script, what it deletes, and its options: [docs/scripts.md](docs/scripts.md).

## Limits

- The scripts target WSL 2 on Windows. The Linux scripts run on plain Linux, but there is no VHD to compact.
- `wsl-space-scan.sh` always scans `/` and all of `$HOME`. It has no option to scan a smaller tree.
- `compose.yml` publishes port 8888 on every host interface, not only on `127.0.0.1`. Anyone who can reach the machine on that port can use the proxy.
- `docker-cleanup.sh` removes every image that no container uses, including images you pulled on purpose. Run `docker-list-images.sh` first.
- Only `wsl-space-scan.sh` (in a sandbox), the usage output of the guarded scripts, and `menu.sh status` were run while this README was written. The cleanup, Docker, PowerShell and VPN scripts were not run.

## License

MIT
