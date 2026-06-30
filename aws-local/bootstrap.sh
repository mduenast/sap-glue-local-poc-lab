#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

echo "Waiting for local AWS-compatible endpoint: ${ENDPOINT_URL}"
ready=0
for _ in $(seq 1 30); do
  if curl -fsS "${ENDPOINT_URL}/_localstack/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  echo "Local AWS-compatible endpoint is not ready: ${ENDPOINT_URL}" >&2
  exit 1
fi

"${SCRIPT_DIR}/create-bucket.sh"
"${SCRIPT_DIR}/create-dynamodb-table.sh"

echo "Local AWS-compatible bootstrap completed."
