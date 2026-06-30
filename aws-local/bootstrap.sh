#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/create-bucket.sh"
"${SCRIPT_DIR}/create-dynamodb-table.sh"

echo "Local AWS-compatible bootstrap completed."
