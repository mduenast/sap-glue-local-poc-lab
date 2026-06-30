# SAP-like Local Data Lab

This repository contains a small, public-safe skeleton for a local executable lab. It simulates:

- a SAP-like operational source using PostgreSQL
- a local S3-compatible and DynamoDB-compatible landing environment exposed on `localhost:4566`
- future extractor and orchestrator packages

The project is intentionally generic. It does not connect to any real SAP system, does not include commercial extractor configuration, and does not implement dbt models. dbt is expected to live in a separate repository in later phases.

## Architecture

```text
PostgreSQL SAP-like source
  -> future extractor simulator
  -> local S3-compatible landing zone
  -> future local orchestrator
  -> future DuckDB analytical file
```

Phase 1 implements the PostgreSQL source simulator and local AWS-compatible bootstrap only.

## Prerequisites

- Docker and Docker Compose
- Make
- Optional AWS CLI compatible tooling for local S3 and DynamoDB commands against `localhost:4566`

## Quickstart

```bash
make up
make bootstrap
make seed-sap
```

This starts PostgreSQL 16 and the local Floci service, creates the local landing bucket and batch-state table, and seeds the SAP-like source tables.

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

Reset the local lab:

```bash
make clean
```

## Repository Layout

- `sap-simulator/`: PostgreSQL schema and seed scripts for SAP-like tables.
- `extractor-simulator/`: Python package skeleton for file and manifest extraction.
- `aws-local/`: Local S3-compatible and DynamoDB bootstrap scripts.
- `orchestrator/`: Python package skeleton for manifest-driven DuckDB loading.
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
- Extractor logic is not implemented in Phase 1.
- Orchestrator and DuckDB loading logic are not implemented in Phase 1.
- The local AWS-compatible resources are only validated for local development behavior.

## Next Phase

The next recommended phase is to implement a minimal end-to-end happy path:

1. Read `config/tables.yml`.
2. Extract each table from PostgreSQL to local Parquet or CSV files.
3. Write a simple manifest per extraction batch.
4. Load manifest-listed files into DuckDB.
5. Persist basic batch state locally.
