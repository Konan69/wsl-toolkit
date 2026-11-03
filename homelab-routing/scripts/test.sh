#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
echo "Direct:"
curl -s https://ifconfig.me
echo
echo "Via gateway:"
curl -s -x http://127.0.0.1:8888 https://ifconfig.me
echo
