#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning generated local data..."
find data -mindepth 1 ! -name ".gitkeep" -exec rm -rf {} +
echo "Local data directory cleaned."
