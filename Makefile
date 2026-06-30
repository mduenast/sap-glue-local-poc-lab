.PHONY: up down bootstrap seed-sap extract load show-results demo clean

COMPOSE ?= docker compose
POSTGRES_SERVICE ?= postgres
POSTGRES_DB ?= sap_source
POSTGRES_USER ?= lab_user
EXTRACTOR_PYTHON ?= $(shell test -x extractor-simulator/.venv/bin/python && echo extractor-simulator/.venv/bin/python || echo python)
ORCHESTRATOR_PYTHON ?= $(shell test -x orchestrator/.venv/bin/python && echo orchestrator/.venv/bin/python || echo python)

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

bootstrap:
	./aws-local/bootstrap.sh

seed-sap:
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB)
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/00_schema.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/01_seed_master_data.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /sap-simulator/sql/02_seed_sales_data.sql

extract:
	@test -n "$(TABLE)" || (echo "Usage: make extract TABLE=VBAK" >&2; exit 1)
	PYTHONPATH=extractor-simulator/src $(EXTRACTOR_PYTHON) -m extractor_simulator.cli extract --config config/tables.yml --table $(TABLE) --mode full

load:
	@test -n "$(TABLE)" || (echo "Usage: make load TABLE=VBAK" >&2; exit 1)
	PYTHONPATH=orchestrator/src $(ORCHESTRATOR_PYTHON) -m local_orchestrator.cli process-latest --table $(TABLE)

show-results:
	PYTHONPATH=orchestrator/src $(ORCHESTRATOR_PYTHON) -m local_orchestrator.cli show-results

demo:
	./scripts/run-demo.sh

clean:
	./scripts/clean.sh
