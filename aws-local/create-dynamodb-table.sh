#!/usr/bin/env bash
set -euo pipefail

ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"
TABLE="${BATCH_STATE_TABLE:-sap-glue-local-lab-batch-state}"

aws --endpoint-url "${ENDPOINT_URL}" dynamodb create-table \
  --table-name "${TABLE}" \
  --attribute-definitions AttributeName=batch_id,AttributeType=S \
  --key-schema AttributeName=batch_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  2>/dev/null || true

echo "Ensured batch-state table exists: ${TABLE}"
