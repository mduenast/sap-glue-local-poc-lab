# Floci Local Emulator

This folder contains minimal bootstrap scripts for the local landing zone.

The Docker Compose service named `floci` exposes the local AWS-compatible emulator on port `4566` by default, including the Floci S3-compatible service and Floci DynamoDB-compatible service.

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

The host must provide AWS CLI-compatible tooling as `aws`.
