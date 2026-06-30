#!/usr/bin/env bash
set -euo pipefail

ENDPOINT_URL="${FLOCI_ENDPOINT_URL:-http://localhost:4566}"
BUCKET="${LANDING_BUCKET:-sap-glue-local-landing}"
REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${REGION}"

if command -v aws >/dev/null 2>&1; then
  aws_cmd=(aws --endpoint-url "${ENDPOINT_URL}")
else
  aws_cmd=(docker compose exec -T floci awslocal)
fi

if "${aws_cmd[@]}" s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
  echo "Landing bucket already exists: ${BUCKET}"
  exit 0
fi

"${aws_cmd[@]}" s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Created landing bucket: ${BUCKET}"
