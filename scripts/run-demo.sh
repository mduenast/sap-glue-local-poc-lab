#!/usr/bin/env bash
set -euo pipefail

echo "Starting local lab demo skeleton..."
make up
make bootstrap
make seed-sap
make extract TABLE=VBAK
make load TABLE=VBAK
make show-results
echo "Demo skeleton completed."
