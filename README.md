# SAP-like Local Data Lab

This repository contains a small, public-safe skeleton for a local executable lab. It simulates:

- a SAP-like operational source using PostgreSQL
- an enterprise-style extractor that will write files and manifests to an S3-compatible landing zone
- a local orchestrator that will read manifests and load data into DuckDB

The project is intentionally generic. It does not connect to any real SAP system, does not include commercial extractor configuration, and does not implement dbt models. dbt is expected to live in a separate repository in later phases.

## Architecture

```text
PostgreSQL SAP-like source
  -> extractor simulator
  -> S3-compatible landing zone provided by Floci
  -> local orchestrator
  -> DuckDB analytical file
```

The first iteration only defines the structure, sample source schema, seed data, package skeletons, and operational entry points.

## Prerequisites

- Docker and Docker Compose
- Make
- Python 3.11 or newer for local package development
- AWS CLI compatible tooling for local S3 and DynamoDB commands

## Quickstart

```bash
make up
make bootstrap
make seed-sap
make extract
make load
make demo
```

The placeholder targets are intentionally light. Later phases will fill in extraction, manifest writing, state tracking, and DuckDB loading behavior.

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
- Extraction and loading logic are TODO skeletons for future phases.

## Next Phase

The next recommended phase is to implement a minimal end-to-end happy path:

1. Read `config/tables.yml`.
2. Extract each table from PostgreSQL to local Parquet or CSV files.
3. Write a simple manifest per extraction batch.
4. Load manifest-listed files into DuckDB.
5. Persist basic batch state locally.
