#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

ensure_env() {
  if [ ! -f .env ]; then
    cp config.example.env .env
    echo "Created .env from config.example.env"
  fi
}

status() {
  echo "Homelab routing status"
  echo

  if command -v docker >/dev/null 2>&1; then
    echo "docker: $(docker --version)"
  else
    echo "docker: missing"
  fi

  if docker compose version >/dev/null 2>&1; then
    echo "compose: $(docker compose version)"
  else
    echo "compose: missing"
  fi

  if [ -f wireguard/wg0.conf ]; then
    echo "wireguard config: present at wireguard/wg0.conf"
  else
    echo "wireguard config: missing"
    echo
    echo "Put a provider WireGuard config here:"
    echo "  $(pwd)/wireguard/wg0.conf"
  fi

  echo
  if docker ps --format '{{.Names}}' | grep -qx homelab-gluetun; then
    echo "gateway: running"
  else
    echo "gateway: stopped"
  fi
}

start() {
  ensure_env
  if [ ! -f wireguard/wg0.conf ]; then
    echo "Missing wireguard/wg0.conf"
    echo
    echo "This gateway needs a WireGuard config from a VPN provider."
    echo "Once you have one, save it as:"
    echo "  $(pwd)/wireguard/wg0.conf"
    exit 1
  fi

  docker compose up -d
  docker compose ps
}

test_gateway() {
  echo "Direct IP:"
  curl -s https://ifconfig.me || true
  echo
  echo
  echo "Gateway IP:"
  curl -s -x http://127.0.0.1:8888 https://ifconfig.me || true
  echo
}

case "${1:-status}" in
  status) status ;;
  start) start ;;
  stop) docker compose down ;;
  test) test_gateway ;;
  logs) docker compose logs -f --tail=120 ;;
  *)
    echo "Usage: ./menu.sh [status|start|stop|test|logs]"
    exit 2
    ;;
esac
