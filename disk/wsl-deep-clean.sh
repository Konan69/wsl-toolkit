#!/usr/bin/env bash
set +e  # keep going even if a step has issues
if [ "${1:-}" != "--clean" ]; then
  echo "Usage: $0 --clean [PATH ...]"
  echo "Deletes PATHs, clears package caches and vacuums the journal to 200M, then runs fstrim."
  exit 2
fi
shift

before=$(df -m / | awk 'NR==2 {print $3}')
echo "=== BEFORE: $(df -h / | awk 'NR==2 {print $3 " used / " $4 " avail"}') ==="
echo ""

for path in "$@"; do
  du -sh -- "$path" 2>/dev/null
  rm -rf -- "$path"
  echo "  removed $path"
done

echo ""
echo "=== Tier 1 caches ==="

echo "--- pnpm store prune (keeps referenced pkgs) ---"
pnpm store prune 2>&1 | tail -3
echo "  done"

echo "--- npm cache clean ---"
npm cache clean --force 2>&1 | tail -2
echo "  done"

echo "--- bun cache ---"
rm -rf ~/.bun/install/cache
echo "  done"

echo "--- uv cache ---"
if command -v uv >/dev/null 2>&1; then
  uv cache clean 2>&1 | tail -2
else
  rm -rf ~/.cache/uv
fi
echo "  done"

echo "--- apt clean ---"
sudo apt clean
echo "  done"

echo "--- journal vacuum to 200M ---"
sudo journalctl --vacuum-size=200M 2>&1 | tail -3
echo "  done"

echo ""
echo "=== fstrim (releases freed blocks; sparse VHD will reclaim space file-side) ==="
sudo fstrim -av

echo ""
after=$(df -m / | awk 'NR==2 {print $3}')
freed_mb=$((before - after))
echo "=== AFTER: $(df -h / | awk 'NR==2 {print $3 " used / " $4 " avail"}') ==="
echo "Freed inside WSL: ~$((freed_mb / 1024)) GiB"
