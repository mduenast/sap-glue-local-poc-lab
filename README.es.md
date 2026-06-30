# Laboratorio local de datos tipo SAP

Este repositorio contiene un esqueleto pequeno y seguro para publicacion de un laboratorio ejecutable en local. Simula:

- una fuente operacional tipo SAP usando PostgreSQL
- un entorno local compatible con S3 y DynamoDB expuesto en `localhost:4566`
- futuros paquetes de extractor y orquestador

El proyecto es intencionadamente generico. No conecta con ningun sistema SAP real, no incluye configuracion de extractores comerciales y no implementa modelos dbt. dbt vivira en un repositorio separado en fases posteriores.

## Arquitectura

```text
Fuente tipo SAP en PostgreSQL
  -> futuro simulador de extractor
  -> zona de aterrizaje local compatible con S3
  -> futuro orquestador local
  -> futuro fichero analitico DuckDB
```

La Fase 1 implementa solo el simulador de fuente PostgreSQL y el bootstrap local compatible con AWS.

## Prerrequisitos

- Docker y Docker Compose
- Make
- Python 3.11 o superior
- Herramientas compatibles con AWS CLI opcionales para comandos locales de S3 y DynamoDB contra `localhost:4566`

## Inicio rapido

```bash
make up
make bootstrap
make seed-sap
python -m venv extractor-simulator/.venv
extractor-simulator/.venv/bin/python -m pip install -e extractor-simulator
PATH="$(pwd)/extractor-simulator/.venv/bin:$PATH" make extract TABLE=VBAK
```

Esto arranca PostgreSQL 16 y el servicio local Floci, crea el bucket local de aterrizaje y la tabla de estado de lotes, carga las tablas fuente tipo SAP y extrae una tabla a Parquet con manifiesto.

## Verificacion

Comprobar los servicios locales:

```bash
docker compose ps
```

Comprobar las tablas simuladas tipo SAP:

```bash
docker compose exec postgres psql -U lab_user -d sap_source -c "\dt"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_mara;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_kna1;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_vbak;"
docker compose exec postgres psql -U lab_user -d sap_source -c "select count(*) from sap_vbap;"
```

Comprobar los recursos locales compatibles con AWS:

```bash
docker compose exec floci awslocal s3api list-buckets
docker compose exec floci awslocal dynamodb list-tables
```

Ejecutar una extraccion completa de la tabla de cabecera de ventas:

```bash
PATH="$(pwd)/extractor-simulator/.venv/bin:$PATH" make extract TABLE=VBAK
```

Listar los artefactos subidos:

```bash
docker compose exec floci awslocal s3 ls \
  s3://sap-glue-local-landing/landing/sap/VBAK/ \
  --recursive
```

Leer el ultimo manifiesto:

```bash
LATEST_MANIFEST="$(docker compose exec -T floci awslocal s3 ls s3://sap-glue-local-landing/landing/sap/VBAK/ --recursive | awk '/manifest.json/ {print $4}' | tail -n 1)"
docker compose exec -T floci awslocal s3 cp "s3://sap-glue-local-landing/${LATEST_MANIFEST}" -
```

Reiniciar el laboratorio local:

```bash
make clean
```

## Estructura

- `sap-simulator/`: esquema PostgreSQL y scripts de datos para tablas tipo SAP.
- `extractor-simulator/`: paquete Python para extraccion full-table a Parquet y manifiestos.
- `aws-local/`: scripts de bootstrap para S3 compatible y DynamoDB local.
- `orchestrator/`: esqueleto Python para carga en DuckDB guiada por manifiestos.
- `config/tables.yml`: metadatos de extraccion de tablas.
- `scripts/`: puntos de entrada para demo, limpieza y visualizacion de resultados.
- `data/`: area local de datos generados, excluida de git salvo `.gitkeep`.

## Limitaciones

- No se incluyen credenciales reales.
- No se incluye integracion con sistemas SAP reales.
- No se incluye configuracion de extractores comerciales.
- No se incluye integracion con Snowflake.
- No se incluye proyecto dbt ni modelos dbt.
- No se hacen afirmaciones de seguridad, monitorizacion u orquestacion de nivel productivo.
- La logica de extractor soporta solo extraccion completa en la Fase 2.
- La extraccion incremental no esta implementada todavia.
- La logica de orquestador y carga en DuckDB no esta implementada todavia.
- Los recursos locales compatibles con AWS solo se validan para comportamiento de desarrollo local.

## Siguiente fase

La siguiente fase recomendada es implementar la carga local guiada por manifiestos:

1. Leer manifiestos desde el bucket local compatible con S3.
2. Descargar o leer los ficheros Parquet indicados por el manifiesto.
3. Cargarlos en DuckDB.
4. Persistir estado basico de lote en local.
