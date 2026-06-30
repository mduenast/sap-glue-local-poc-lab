# Local AWS-Compatible Services

This folder contains minimal bootstrap scripts for the local landing zone.

The Docker Compose service named `floci` exposes S3-compatible and DynamoDB-compatible APIs on port `4566` by default.

## Scripts

- `bootstrap.sh`: runs all local bootstrap tasks
- `create-bucket.sh`: creates the `sap-glue-local-landing` landing bucket if needed
- `create-dynamodb-table.sh`: creates the `sap_ingestion_batches` batch-state table if needed

## Usage

```bash
make up
make bootstrap
```

The scripts use placeholder local credentials from `.env.example`. They do not contain real credentials.

If the host AWS CLI is not installed, the scripts use `awslocal` inside the running `floci` container.
