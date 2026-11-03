#!/usr/bin/env bash
set -e
if [ "${1:-}" != "--prune" ]; then
  echo "Usage: $0 --prune"
  echo "Prunes unused Docker data."
  exit 2
fi
echo "=== BEFORE ==="
sudo docker system df
echo ""
echo "=== Prune dangling build cache only (no -a) ==="
sudo docker builder prune -f
echo ""
echo "=== AFTER ==="
sudo docker system df
echo ""
echo "=== ALL containers (including stopped) ==="
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Size}}'
echo ""
echo "=== ALL volumes ==="
sudo docker volume ls --format 'table {{.Name}}\t{{.Driver}}'
echo ""
echo "=== Volume sizes (top 30) ==="
for v in $(sudo docker volume ls -q); do
  mp=$(sudo docker volume inspect -f '{{.Mountpoint}}' "$v")
  size=$(sudo du -sh "$mp" 2>/dev/null | cut -f1)
  echo "$size  $v"
done | sort -h -r | head -30
