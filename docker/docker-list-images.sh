#!/usr/bin/env bash
set -e
sudo docker info >/dev/null

echo "=== ACTIVE images (referenced by a container, any state) ==="
active=$(sudo docker ps -a --format '{{.Image}}' | sort -u)
while IFS= read -r img; do
  size=$(sudo docker images "$img" --format '{{.Size}}' 2>/dev/null | head -1)
  printf "%10s  %s\n" "$size" "$img"
done <<< "$active" | sort -h -r

echo ""
echo "=== IDLE images that 'docker image prune -af' WILL DELETE ==="
sudo docker images --format '{{.Repository}}:{{.Tag}}|{{.Size}}|{{.ID}}' | while IFS='|' read -r repo size id; do
  if ! grep -qxF "$repo" <<< "$active"; then
    printf "%10s  %s  (%s)\n" "$size" "$repo" "$id"
  fi
done | sort -h -r
