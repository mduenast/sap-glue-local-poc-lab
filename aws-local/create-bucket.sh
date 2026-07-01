#!/usr/bin/env bash
set -euo pipefail

AWS_CLI="${AWS_BIN:-aws}"
ENDPOINT_URL="${AWS_ENDPOINT_URL:-${FLOCI_ENDPOINT_URL:-http://localhost:4566}}"
BUCKET="${LANDING_BUCKET:-sap-glue-local-landing}"
REGION="${AWS_DEFAULT_REGION:-eu-west-1}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${REGION}"
export AWS_ENDPOINT_URL="${ENDPOINT_URL}"

if [ ! -x "${AWS_CLI}" ] && ! command -v "${AWS_CLI}" >/dev/null 2>&1; then
  echo "AWS CLI-compatible binary not found at ${AWS_CLI}." >&2
  echo "Run make setup to install awscli into the local lab tooling virtual environment, or pass AWS_BIN=/path/to/aws." >&2
  exit 1
fi

aws_cmd=("${AWS_CLI}" --endpoint-url "${ENDPOINT_URL}" --cli-connect-timeout 5 --cli-read-timeout 5)

if "${aws_cmd[@]}" s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
  echo "Landing bucket already exists: ${BUCKET}"
  exit 0
fi

"${aws_cmd[@]}" s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Created landing bucket: ${BUCKET}"
