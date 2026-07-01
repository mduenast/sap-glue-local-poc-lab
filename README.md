# SAP-like Local Data Lab

This repository contains a small, public-safe skeleton for a local executable lab. It simulates:

- a SAP-like operational source using PostgreSQL
- Floci as the local AWS-compatible emulator exposed on `localhost:4566`
- an extractor simulator that writes Parquet files and manifests
- a local manifest-driven orchestrator that loads DuckDB RAW tables
- an optional final call to a separate dbt project cloned next to this repository

The project is intentionally generic. It does not connect to any real SAP system, does not include commercial extractor configuration, and does not contain dbt models. dbt lives in a separate repository.

## Architecture

```text
PostgreSQL SAP-like source
  -> extractor simulator
  -> Floci S3-compatible service
  -> local orchestrator
  -> DuckDB RAW tables
  -> external dbt project
```

The local demo can run the full generic flow through the external dbt project without copying dbt models into this repository.

## Folder Layout

Clone the two repositories side by side:

```text
parent-folder/
  sap-glue-local-poc-lab/
  sap-glue-local-poc-dbt/
```

The lab writes DuckDB to:

```text
sap-glue-local-poc-lab/data/warehouse/local_lab.duckdb
```

`make dbt-build` uses the dbt binary from the sibling repository virtual environment by default:

```text
../sap-glue-local-poc-dbt/.venv/bin/dbt
```

It passes `DUCKDB_PATH` as an absolute path to the DuckDB file. The dbt profile example should use that `DUCKDB_PATH` environment variable.

## Prerequisites

- Docker and Docker Compose
- Make
- Python 3.11 or newer

The lab installs AWS CLI-compatible tooling locally into `.venv/` with `make setup`; a globally installed `aws` command is not required.

## dbt Sibling Project Setup

This repository does not install dbt automatically and does not include dbt models. Create the dbt environment explicitly in the sibling dbt repository:

```bash
cd ../sap-glue-local-poc-dbt
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e .
```

If the sibling dbt project uses a requirements file instead of an editable package, install that file from the sibling repository:

```bash
.venv/bin/python -m pip install -r requirements.txt
```

From this lab repository, `make dbt-build` defaults to:

```make
DBT_PROJECT_DIR ?= ../sap-glue-local-poc-dbt
DBT_BIN ?= $(DBT_PROJECT_DIR)/.venv/bin/dbt
```

Override either value when the sibling project is somewhere else or when you want to use a different dbt executable. The sibling dbt project should manage its own setup; this lab does not install dbt.

```bash
make dbt-build DBT_PROJECT_DIR=../my-dbt-project
make dbt-build DBT_BIN=/absolute/path/to/dbt
```

## Quickstart

```bash
make setup
make up
make bootstrap
make demo
```

This installs local lab tooling and Python package dependencies, starts PostgreSQL 16 and Floci, creates the local landing bucket and batch-state table, seeds the SAP-like source tables, extracts data to Parquet plus manifests, loads DuckDB RAW tables, runs dbt from the sibling repository, and shows local results.

`make setup` creates:

```text
.venv/                         # local lab tools, including awscli
extractor-simulator/.venv/     # extractor dependencies
orchestrator/.venv/            # orchestrator dependencies
```

You can override the local AWS CLI-compatible binary if needed:

```bash
make bootstrap AWS_BIN=/absolute/path/to/aws
```

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

Check the Floci resources:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3api list-buckets
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 dynamodb list-tables
```

Run a full extraction for the sales header table:

```bash
make extract TABLE=VBAK
```

List the uploaded extraction artifacts:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 ls \
  s3://sap-glue-local-landing/landing/sap/VBAK/ \
  --recursive
```

Read the latest manifest:

```bash
LATEST_MANIFEST="$(AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 ls s3://sap-glue-local-landing/landing/sap/VBAK/ --recursive | awk '/manifest.json/ {print $4}' | tail -n 1)"
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 cp "s3://sap-glue-local-landing/${LATEST_MANIFEST}" -
```

Load the latest manifest into DuckDB:

```bash
make load TABLE=VBAK
make show-results
```

The orchestrator writes to RAW tables named `raw_sap_<lower_table>`, for example `raw_sap_vbak`. It adds `_batch_id`, `_source_table`, `_loaded_at`, and `_file_name` technical columns. Re-running `make load TABLE=VBAK` skips a batch that is already marked `SUCCESS` in `sap_ingestion_batches`.

Run the external dbt project:

```bash
make dbt-build
```

Run the local demo flow for all four tables:

```bash
make demo
```

`make demo` runs bootstrap, seeds the source, extracts and loads `MARA`, `KNA1`, `VBAK`, and `VBAP`, calls the dbt binary from `../sap-glue-local-poc-dbt/.venv/bin/dbt`, then shows local results. If the sibling dbt repository or virtual environment is missing, the command fails with a clear actionable message.

Reset the local lab:

```bash
make clean
```

## SAP-Like Schema

The PostgreSQL simulator exposes four generic SAP-like tables:

- `sap_mara`: `mandt`, `matnr`, `mtart`, `matkl`, `meins`, `ersda`, `erdat`, `aedat`
- `sap_kna1`: `mandt`, `kunnr`, `name1`, `land1`, `ort01`, `erdat`, `aedat`
- `sap_vbak`: `mandt`, `vbeln`, `kunnr`, `audat`, `auart`, `vkorg`, `erdat`, `aedat`, `waers`, `waerk`, `netwr`
- `sap_vbap`: `mandt`, `vbeln`, `posnr`, `matnr`, `kwmeng`, `vrkme`, `waerk`, `netwr`, `erdat`, `aedat`

## Manifest Contract

The extractor writes `manifest.json` beside each Parquet file. The manifest includes:

- `source_system: "SAP_SIM"`
- `extractor: "EXTRACTOR_SIMULATOR"`
- `table` and `source_table`
- `mode`, `batch_id`, `load_date`, `status`
- `format: "parquet"`
- `files`, as objects with `uri` and `rows`
- `total_rows`
- `created_at`

The orchestrator accepts this manifest shape and keeps simple backward compatibility with older manifests where `files` was a list of URI strings.

## Repository Layout

- `sap-simulator/`: PostgreSQL schema and seed scripts for SAP-like tables.
- `extractor-simulator/`: Python package for full-table extraction to Parquet and manifest files.
- `aws-local/`: Floci S3-compatible and DynamoDB-compatible bootstrap scripts.
- `orchestrator/`: Python package for manifest-driven DuckDB RAW loading.
- `config/tables.yml`: Table extraction metadata.
- `scripts/`: Demo, cleanup, and result-display entry points.
- `data/`: Local generated data area, kept out of git except for `.gitkeep`.

## Limitations

- No real credentials are included.
- No real SAP system integration is included.
- No commercial extractor configuration is included.
- No Snowflake integration is included.
- No dbt project or dbt models are included in this repository.
- No production-grade security, monitoring, or orchestration claims are made.
- Extractor logic supports full-table extraction only in Phase 2.
- Incremental extraction is not implemented yet.
- Orchestrator loading supports manifest-driven local RAW tables only.
- Batch idempotency is tracked by `table_name` and `batch_id` in the Floci DynamoDB-compatible service.
- dbt execution is a simple shell handoff to the sibling repository only.
- The Floci resources are only validated for local development behavior.

## Next Phase

The next recommended phase is to harden the local transformation handoff:

1. Add explicit checks that the expected dbt profiles and packages are installed.
2. Add lightweight data quality checks around RAW row counts.
3. Add a simple results summary for transformed tables.
