#!/usr/bin/env bash
set -euo pipefail

AWS_CLI="${AWS_BIN:-aws}"
ENDPOINT_URL="${AWS_ENDPOINT_URL:-${FLOCI_ENDPOINT_URL:-http://localhost:4566}}"
TABLE="${BATCH_STATE_TABLE:-sap_ingestion_batches}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"
export AWS_ENDPOINT_URL="${ENDPOINT_URL}"

if [ ! -x "${AWS_CLI}" ] && ! command -v "${AWS_CLI}" >/dev/null 2>&1; then
  echo "AWS CLI-compatible binary not found at ${AWS_CLI}." >&2
  echo "Run make setup to install awscli into the local lab tooling virtual environment, or pass AWS_BIN=/path/to/aws." >&2
  exit 1
fi

aws_cmd=("${AWS_CLI}" --endpoint-url "${ENDPOINT_URL}" --cli-connect-timeout 5 --cli-read-timeout 5)

if "${aws_cmd[@]}" dynamodb describe-table --table-name "${TABLE}" >/dev/null 2>&1; then
  key_attributes="$("${aws_cmd[@]}" dynamodb describe-table \
    --table-name "${TABLE}" \
    --query "Table.KeySchema[].AttributeName" \
    --output text)"
  if [ "${key_attributes}" != "table_name	batch_id" ]; then
    echo "Batch-state table ${TABLE} exists with incompatible key schema: ${key_attributes}." >&2
    echo "Run make clean, then make up and make bootstrap to recreate local Floci state." >&2
    exit 1
  fi
  echo "Batch-state table already exists with table_name + batch_id key: ${TABLE}"
  exit 0
fi

"${aws_cmd[@]}" dynamodb create-table \
  --table-name "${TABLE}" \
  --attribute-definitions AttributeName=table_name,AttributeType=S AttributeName=batch_id,AttributeType=S \
  --key-schema AttributeName=table_name,KeyType=HASH AttributeName=batch_id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

echo "Created batch-state table: ${TABLE}"
