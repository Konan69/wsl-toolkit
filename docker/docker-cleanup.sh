#!/usr/bin/env bash
set -e
if [ "${1:-}" != "--prune" ]; then
  echo "Usage: $0 --prune"
  echo "Prunes unused Docker data."
  exit 2
fi

echo "=== Ensure docker daemon is up ==="
sudo systemctl start docker
sleep 2
sudo docker info >/dev/null

echo ""
echo "=== Image prune (-af: removes ALL unused images, not just dangling) ==="
sudo docker image prune -af

echo ""
echo "=== Anonymous volumes only (64-hex names) — skip everything named ==="
echo "Named volumes that will be PRESERVED:"
sudo docker volume ls --format '{{.Name}}' | grep -Ev '^[0-9a-f]{64}$' || true
echo ""
echo "Anonymous volumes to evaluate:"
anon=$(sudo docker volume ls --format '{{.Name}}' | grep -E '^[0-9a-f]{64}$' || true)
removed=0
kept=0
for v in $anon; do
  # Skip if currently attached to any container (running or stopped)
  in_use=$(sudo docker ps -a --filter "volume=$v" --format '{{.Names}}' | head -1)
  if [ -n "$in_use" ]; then
    echo "  KEEP $v (attached to: $in_use)"
    kept=$((kept+1))
  else
    sudo docker volume rm "$v" >/dev/null
    echo "  REMOVED $v"
    removed=$((removed+1))
  fi
done
echo "Anonymous volumes: removed=$removed kept=$kept"

echo ""
echo "=== Final docker system df ==="
sudo docker system df

echo ""
echo "=== fstrim (releases freed blocks to the VHD) ==="
sudo fstrim -av

echo ""
echo "=== Filesystem usage after cleanup ==="
df -h /
