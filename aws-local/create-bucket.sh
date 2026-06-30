#!/usr/bin/env bash
set -euo pipefail

ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"
BUCKET="${LANDING_BUCKET:-sap-glue-local-lab-landing}"
REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

aws --endpoint-url "${ENDPOINT_URL}" s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}" \
  2>/dev/null || true

echo "Ensured landing bucket exists: ${BUCKET}"
