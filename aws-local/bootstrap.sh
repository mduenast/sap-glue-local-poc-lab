#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_BIN:-aws}"
ENDPOINT_URL="${AWS_ENDPOINT_URL:-${FLOCI_ENDPOINT_URL:-http://localhost:4566}}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"
export AWS_ENDPOINT_URL="${ENDPOINT_URL}"

if [ ! -x "${AWS_CLI}" ] && ! command -v "${AWS_CLI}" >/dev/null 2>&1; then
  echo "AWS CLI-compatible binary not found at ${AWS_CLI}." >&2
  echo "Run make setup to install awscli into the local lab tooling virtual environment, or pass AWS_BIN=/path/to/aws." >&2
  exit 1
fi

echo "Waiting for Floci endpoint: ${ENDPOINT_URL}"
ready=0
for _ in $(seq 1 30); do
  if "${AWS_CLI}" --endpoint-url "${ENDPOINT_URL}" --cli-connect-timeout 2 --cli-read-timeout 2 s3api list-buckets >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  echo "Floci endpoint is not ready: ${ENDPOINT_URL}" >&2
  exit 1
fi

AWS_BIN="${AWS_CLI}" "${SCRIPT_DIR}/create-bucket.sh"
AWS_BIN="${AWS_CLI}" "${SCRIPT_DIR}/create-dynamodb-table.sh"

echo "Floci bootstrap completed."
