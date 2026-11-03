#!/usr/bin/env bash
echo "=== / overall ==="
df -h /
echo ""
echo "=== Top-level dirs (>500 MB) ==="
sudo du -hxd1 / 2>/dev/null | awk '$1 ~ /[0-9]G/ || ($1 ~ /M/ && $1+0 >= 500)' | sort -h -r
echo ""
echo "=== /var subdirs (>200 MB) ==="
sudo du -hxd1 /var 2>/dev/null | awk '$1 ~ /G/ || ($1 ~ /M/ && $1+0 >= 200)' | sort -h -r
echo ""
echo "=== $HOME subdirs (>200 MB) ==="
sudo du -hxd1 "$HOME" 2>/dev/null | awk '$1 ~ /G/ || ($1 ~ /M/ && $1+0 >= 200)' | sort -h -r
echo ""
echo "=== Caches (apt, snap, journal, pip, npm, pnpm, cargo, etc.) ==="
echo -n "apt archives:       "; sudo du -sh /var/cache/apt/archives 2>/dev/null | cut -f1
echo -n "journal logs:       "; sudo journalctl --disk-usage 2>/dev/null | awk -F'take up ' '{print $2}'
echo -n "snap (if any):      "; sudo du -sh /var/lib/snapd 2>/dev/null | cut -f1 || echo "n/a"
echo -n "~/.cache:           "; du -sh ~/.cache 2>/dev/null | cut -f1
echo -n "~/.npm:             "; du -sh ~/.npm 2>/dev/null | cut -f1
echo -n "~/.local/share/pnpm:"; du -sh ~/.local/share/pnpm 2>/dev/null | cut -f1
echo -n "~/.cargo:           "; du -sh ~/.cargo 2>/dev/null | cut -f1
echo -n "~/.rustup:          "; du -sh ~/.rustup 2>/dev/null | cut -f1
echo -n "~/.cache/pip:       "; du -sh ~/.cache/pip 2>/dev/null | cut -f1
echo -n "~/.cache/uv:        "; du -sh ~/.cache/uv 2>/dev/null | cut -f1
echo -n "~/.cache/yarn:      "; du -sh ~/.cache/yarn 2>/dev/null | cut -f1
echo -n "~/.bun:             "; du -sh ~/.bun 2>/dev/null | cut -f1
echo -n "~/.deno:            "; du -sh ~/.deno 2>/dev/null | cut -f1
echo -n "~/.gradle:          "; du -sh ~/.gradle 2>/dev/null | cut -f1
echo -n "~/.m2:              "; du -sh ~/.m2 2>/dev/null | cut -f1
echo -n "/tmp:               "; sudo du -sh /tmp 2>/dev/null | cut -f1
echo -n "/var/tmp:           "; sudo du -sh /var/tmp 2>/dev/null | cut -f1
echo ""
echo "=== node_modules trees larger than 200 MB (under ~) ==="
find ~ -type d -name node_modules -prune 2>/dev/null | while read -r d; do
  s=$(du -sh "$d" 2>/dev/null | cut -f1)
  echo "$s  $d"
done | awk '$1 ~ /G/ || ($1 ~ /M/ && $1+0 >= 200)' | sort -h -r | head -20
echo ""
echo "=== Build/dist trees (target/, dist/, build/, .next/) larger than 200 MB ==="
for name in target dist build .next .turbo .venv venv __pycache__; do
  find ~ -type d -name "$name" -prune 2>/dev/null | while read -r d; do
    s=$(du -sh "$d" 2>/dev/null | cut -f1)
    echo "$s  $d"
  done
done | awk '$1 ~ /G/ || ($1 ~ /M/ && $1+0 >= 200)' | sort -h -r | head -30
