.PHONY: setup setup-tools setup-extractor setup-orchestrator up down bootstrap seed-sap extract load dbt-build show-results demo clean

COMPOSE ?= docker compose
POSTGRES_SERVICE ?= postgres
POSTGRES_DB ?= sap_source
POSTGRES_USER ?= lab_user
PYTHON ?= python
TOOLS_VENV ?= .venv
AWS_BIN ?= $(TOOLS_VENV)/bin/aws
EXTRACTOR_PYTHON ?= extractor-simulator/.venv/bin/python
ORCHESTRATOR_PYTHON ?= orchestrator/.venv/bin/python
TABLES ?= MARA KNA1 VBAK VBAP
DBT_PROJECT_DIR ?= ../sap-glue-local-poc-dbt
DEFAULT_DBT_BIN = $(DBT_PROJECT_DIR)/.venv/bin/dbt
DBT_BIN ?= $(DEFAULT_DBT_BIN)
DUCKDB_PATH ?= ./data/warehouse/local_lab.duckdb
DBT_DUCKDB_PATH ?= $(abspath $(DUCKDB_PATH))

setup: setup-tools setup-extractor setup-orchestrator

setup-tools:
	@test -f requirements-tools.txt || (echo "requirements-tools.txt not found. Cannot install local lab tools." >&2; exit 1)
	@test -d "$(TOOLS_VENV)" || "$(PYTHON)" -m venv "$(TOOLS_VENV)"
	"$(TOOLS_VENV)/bin/python" -m pip install --upgrade pip
	"$(TOOLS_VENV)/bin/python" -m pip install -r requirements-tools.txt

setup-extractor:
	@test -d extractor-simulator/.venv || "$(PYTHON)" -m venv extractor-simulator/.venv
	extractor-simulator/.venv/bin/python -m pip install --upgrade pip
	extractor-simulator/.venv/bin/python -m pip install -e extractor-simulator

setup-orchestrator:
	@test -d orchestrator/.venv || "$(PYTHON)" -m venv orchestrator/.venv
	orchestrator/.venv/bin/python -m pip install --upgrade pip
	orchestrator/.venv/bin/python -m pip install -e orchestrator

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

bootstrap: setup-tools
	AWS_BIN="$(AWS_BIN)" AWS_ENDPOINT_URL="http://localhost:4566" AWS_ACCESS_KEY_ID="test" AWS_SECRET_ACCESS_KEY="test" AWS_DEFAULT_REGION="eu-west-1" ./aws-local/bootstrap.sh

seed-sap:
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB)
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/00_schema.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/01_seed_master_data.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/02_seed_sales_data.sql

extract:
	@test -n "$(TABLE)" || (echo "Usage: make extract TABLE=VBAK" >&2; exit 1)
	@test -x "$(EXTRACTOR_PYTHON)" || (echo "Extractor Python not found at $(EXTRACTOR_PYTHON). Run make setup to create the local extractor environment." >&2; exit 1)
	PYTHONPATH=extractor-simulator/src $(EXTRACTOR_PYTHON) -m extractor_simulator.cli extract --config config/tables.yml --table $(TABLE) --mode full

load:
	@test -n "$(TABLE)" || (echo "Usage: make load TABLE=VBAK" >&2; exit 1)
	@test -x "$(ORCHESTRATOR_PYTHON)" || (echo "Orchestrator Python not found at $(ORCHESTRATOR_PYTHON). Run make setup to create the local orchestrator environment." >&2; exit 1)
	PYTHONPATH=orchestrator/src $(ORCHESTRATOR_PYTHON) -m local_orchestrator.cli process-latest --table $(TABLE)

show-results:
	@test -x "$(ORCHESTRATOR_PYTHON)" || (echo "Orchestrator Python not found at $(ORCHESTRATOR_PYTHON). Run make setup to create the local orchestrator environment." >&2; exit 1)
	PYTHONPATH=orchestrator/src $(ORCHESTRATOR_PYTHON) -m local_orchestrator.cli show-results

dbt-build:
	@test -d "$(DBT_PROJECT_DIR)" || (echo "dbt project not found at $(DBT_PROJECT_DIR). Clone it next to this repository as ../sap-glue-local-poc-dbt." >&2; exit 1)
	@test -f "$(DBT_DUCKDB_PATH)" || (echo "DuckDB database not found at $(DBT_DUCKDB_PATH). Run make load TABLE=VBAK or make demo after extracting/loading data." >&2; exit 1)
	@if [ "$(DBT_BIN)" = "$(DEFAULT_DBT_BIN)" ] && [ ! -d "$(DBT_PROJECT_DIR)/.venv" ]; then echo "dbt virtual environment not found at $(DBT_PROJECT_DIR)/.venv. Create it in the sibling dbt repository, then install that project's dbt dependencies." >&2; exit 1; fi
	@test -x "$(DBT_BIN)" || (echo "dbt binary not found or not executable at $(DBT_BIN). Create the sibling dbt virtual environment and install dbt, or override DBT_BIN=/path/to/dbt." >&2; exit 1)
	DUCKDB_PATH="$(DBT_DUCKDB_PATH)" "$(DBT_BIN)" build --profiles-dir "$(DBT_PROJECT_DIR)" --project-dir "$(DBT_PROJECT_DIR)"

demo:
	$(MAKE) up
	$(MAKE) bootstrap
	$(MAKE) seed-sap
	@for table in $(TABLES); do $(MAKE) extract TABLE=$$table; done
	@for table in $(TABLES); do $(MAKE) load TABLE=$$table; done
	$(MAKE) dbt-build
	$(MAKE) show-results

clean:
	./scripts/clean.sh
