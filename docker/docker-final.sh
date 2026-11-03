#!/usr/bin/env bash
set -e
if [ "${1:-}" != "--prune" ]; then
  echo "Usage: $0 --prune"
  echo "Prunes Docker data. docker-final.sh also removes REMOVE_CONTAINERS and REMOVE_IMAGES, supplied as space-separated environment variables."
  exit 2
fi

sudo systemctl start docker >/dev/null 2>&1
sleep 2
sudo docker info >/dev/null

echo "=== BEFORE ==="
sudo docker system df
echo ""

read -r -a TO_REMOVE_CONTAINERS <<< "${REMOVE_CONTAINERS:-}"
read -r -a TO_REMOVE_IMAGES <<< "${REMOVE_IMAGES:-}"

echo "=== Removing containers ==="
for c in "${TO_REMOVE_CONTAINERS[@]}"; do
  if sudo docker container inspect "$c" >/dev/null 2>&1; then
    sudo docker rm -f "$c" >/dev/null && echo "  removed $c"
  else
    echo "  not found: $c"
  fi
done

echo ""
echo "=== Removing specific images (after their containers are gone) ==="
for img in "${TO_REMOVE_IMAGES[@]}"; do
  if sudo docker image inspect "$img" >/dev/null 2>&1; then
    sudo docker rmi "$img" 2>&1 | tail -1
  fi
done

echo ""
echo "=== Image prune (cleans up any now-orphaned base layers) ==="
sudo docker image prune -af | tail -2

echo ""
echo "=== Build cache prune ==="
sudo docker builder prune -f | tail -2

echo ""
echo "=== AFTER ==="
sudo docker system df
echo ""
echo "=== Remaining images ==="
sudo docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}' | sort -h -r

echo ""
echo "=== fstrim ==="
sudo fstrim -av

echo ""
df -h /
