.PHONY: up down bootstrap seed-sap extract load demo clean

COMPOSE ?= docker compose
POSTGRES_SERVICE ?= postgres
POSTGRES_DB ?= sap_source
POSTGRES_USER ?= lab_user

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

bootstrap:
	./aws-local/bootstrap.sh

seed-sap:
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /docker-entrypoint-initdb.d/00_schema.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /docker-entrypoint-initdb.d/01_seed_master_data.sql
	$(COMPOSE) exec -T $(POSTGRES_SERVICE) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /docker-entrypoint-initdb.d/02_seed_sales_data.sql

extract:
	cd extractor-simulator && PYTHONPATH=src python -m extractor_simulator.cli extract --config ../config/tables.yml

load:
	cd orchestrator && PYTHONPATH=src python -m local_orchestrator.cli load --manifest-root ../data/landing/manifests

demo:
	./scripts/run-demo.sh

clean:
	./scripts/clean.sh
