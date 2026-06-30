#!/usr/bin/env bash
set -euo pipefail

echo "Starting local lab demo skeleton..."
make up
make bootstrap
make seed-sap
make extract
make load
echo "Demo skeleton completed."
