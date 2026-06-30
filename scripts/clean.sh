#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning generated local data..."
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose down -v --remove-orphans
else
  echo "Docker daemon is not available; skipping container and volume cleanup."
fi
find data -mindepth 1 ! -name ".gitkeep" -exec rm -rf {} +
echo "Local lab containers, volumes, and data directory cleaned."
