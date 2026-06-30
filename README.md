# SAP-like Local Data Lab

This repository contains a small, public-safe skeleton for a local executable lab. It simulates:

- a SAP-like operational source using PostgreSQL
- a local S3-compatible and DynamoDB-compatible landing environment exposed on `localhost:4566`
- an extractor simulator that writes Parquet files and manifests
- a local manifest-driven orchestrator that loads DuckDB RAW tables

The project is intentionally generic. It does not connect to any real SAP system, does not include commercial extractor configuration, and does not implement dbt models. dbt is expected to live in a separate repository in later phases.

## Architecture

```text
PostgreSQL SAP-like source
  -> extractor simulator
  -> local S3-compatible landing zone
  -> local orchestrator
  -> DuckDB RAW tables
```

Phase 3 implements manifest-driven local loading into DuckDB RAW tables and batch-state tracking in local DynamoDB-compatible storage.

## Prerequisites

- Docker and Docker Compose
- Make
- Python 3.11 or newer
- Optional AWS CLI compatible tooling for local S3 and DynamoDB commands against `localhost:4566`

## Quickstart

```bash
make up
make bootstrap
make seed-sap
python -m venv extractor-simulator/.venv
extractor-simulator/.venv/bin/python -m pip install -e extractor-simulator
python -m venv orchestrator/.venv
orchestrator/.venv/bin/python -m pip install -e orchestrator
make extract TABLE=VBAK
make load TABLE=VBAK
make show-results
```

This starts PostgreSQL 16 and the local Floci service, creates the local landing bucket and batch-state table, seeds the SAP-like source tables, extracts one table to Parquet plus a manifest, and loads the latest manifest into DuckDB.

## Verification

Check the local services:

```bash
docker compose ps
```

Check the simulated SAP-like tables:

```bash
docker compose exec postgres psql -U lab_user -d sap_source -c "\dt"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_mara;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_kna1;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_vbak;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_vbap;"
```

Check the local AWS-compatible resources:

```bash
docker compose exec floci awslocal s3api list-buckets
docker compose exec floci awslocal dynamodb list-tables
```

Run a full extraction for the sales header table:

```bash
make extract TABLE=VBAK
```

List the uploaded extraction artifacts:

```bash
docker compose exec floci awslocal s3 ls \
  s3://sap-glue-local-landing/landing/sap/VBAK/ \
  --recursive
```

Read the latest manifest:

```bash
LATEST_MANIFEST="$(docker compose exec -T floci awslocal s3 ls s3://sap-glue-local-landing/landing/sap/VBAK/ --recursive | awk '/manifest.json/ {print $4}' | tail -n 1)"
docker compose exec -T floci awslocal s3 cp "s3://sap-glue-local-landing/${LATEST_MANIFEST}" -
```

Load the latest manifest into DuckDB:

```bash
make load TABLE=VBAK
make show-results
```

The orchestrator writes to RAW tables named `raw_sap_<lower_table>`, for example `raw_sap_vbak`. It adds `_batch_id`, `_source_table`, `_loaded_at`, and `_file_name` technical columns. Re-running `make load TABLE=VBAK` skips a batch that is already marked `SUCCESS` in `sap_ingestion_batches`.

Reset the local lab:

```bash
make clean
```

## Repository Layout

- `sap-simulator/`: PostgreSQL schema and seed scripts for SAP-like tables.
- `extractor-simulator/`: Python package for full-table extraction to Parquet and manifest files.
- `aws-local/`: Local S3-compatible and DynamoDB bootstrap scripts.
- `orchestrator/`: Python package for manifest-driven DuckDB RAW loading.
- `config/tables.yml`: Table extraction metadata.
- `scripts/`: Demo, cleanup, and result-display entry points.
- `data/`: Local generated data area, kept out of git except for `.gitkeep`.

## Limitations

- No real credentials are included.
- No real SAP system integration is included.
- No commercial extractor configuration is included.
- No Snowflake integration is included.
- No dbt project or dbt models are included.
- No production-grade security, monitoring, or orchestration claims are made.
- Extractor logic supports full-table extraction only in Phase 2.
- Incremental extraction is not implemented yet.
- Orchestrator loading supports manifest-driven local RAW tables only.
- Batch idempotency is tracked by `batch_id` in local DynamoDB-compatible storage.
- No dbt execution is implemented yet.
- The local AWS-compatible resources are only validated for local development behavior.

## Next Phase

The next recommended phase is to implement local transformation handoff:

1. Define the contract between RAW tables and a separate dbt repository.
2. Add lightweight data quality checks around RAW row counts.
3. Add a local command that prepares DuckDB for downstream transformations.
