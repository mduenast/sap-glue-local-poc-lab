#!/usr/bin/env bash
set -euo pipefail

ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"
TABLE="${BATCH_STATE_TABLE:-sap_ingestion_batches}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

if command -v aws >/dev/null 2>&1; then
  aws_cmd=(aws --endpoint-url "${ENDPOINT_URL}")
else
  aws_cmd=(docker compose exec -T floci awslocal)
fi

if "${aws_cmd[@]}" dynamodb describe-table --table-name "${TABLE}" >/dev/null 2>&1; then
  echo "Batch-state table already exists: ${TABLE}"
  exit 0
fi

"${aws_cmd[@]}" dynamodb create-table \
  --table-name "${TABLE}" \
  --attribute-definitions AttributeName=batch_id,AttributeType=S \
  --key-schema AttributeName=batch_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "Created batch-state table: ${TABLE}"
