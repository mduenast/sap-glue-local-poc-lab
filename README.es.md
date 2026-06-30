# Laboratorio local de datos tipo SAP

Este repositorio contiene un esqueleto pequeno y seguro para publicacion de un laboratorio ejecutable en local. Simula:

- una fuente operacional tipo SAP usando PostgreSQL
- un entorno local compatible con S3 y DynamoDB expuesto en `localhost:4566`
- un simulador de extractor que escribe ficheros Parquet y manifiestos
- un orquestador local guiado por manifiestos que carga tablas RAW en DuckDB
- una llamada final opcional a un proyecto dbt separado clonado junto a este repositorio

El proyecto es intencionadamente generico. No conecta con ningun sistema SAP real, no incluye configuracion de extractores comerciales y no contiene modelos dbt. dbt vive en un repositorio separado.

## Arquitectura

```text
Fuente tipo SAP en PostgreSQL
  -> simulador de extractor
  -> zona de aterrizaje local compatible con S3
  -> orquestador local
  -> tablas RAW en DuckDB
  -> proyecto dbt externo
```

La demo local puede ejecutar el flujo generico completo hasta el proyecto dbt externo sin copiar modelos dbt en este repositorio.

## Estructura de carpetas

Clonar los dos repositorios uno junto al otro:

```text
carpeta-padre/
  sap-glue-local-poc-lab/
  sap-glue-local-poc-dbt/
```

El laboratorio escribe DuckDB en:

```text
sap-glue-local-poc-lab/data/warehouse/local_lab.duckdb
```

`make dbt-build` se ejecuta dentro de `../sap-glue-local-poc-dbt` y pasa `DUCKDB_PATH` como ruta absoluta a ese fichero DuckDB. El ejemplo de profile de dbt debe usar esa variable de entorno `DUCKDB_PATH`.

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
python -m venv orchestrator/.venv
orchestrator/.venv/bin/python -m pip install -e orchestrator
make extract TABLE=VBAK
make load TABLE=VBAK
make show-results
```

Esto arranca PostgreSQL 16 y el servicio local Floci, crea el bucket local de aterrizaje y la tabla de estado de lotes, carga las tablas fuente tipo SAP, extrae una tabla a Parquet con manifiesto y carga el ultimo manifiesto en DuckDB.

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
make extract TABLE=VBAK
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

Cargar el ultimo manifiesto en DuckDB:

```bash
make load TABLE=VBAK
make show-results
```

El orquestador escribe en tablas RAW llamadas `raw_sap_<lower_table>`, por ejemplo `raw_sap_vbak`. Anade las columnas tecnicas `_batch_id`, `_source_table`, `_loaded_at` y `_file_name`. Al repetir `make load TABLE=VBAK`, se omite un lote que ya esta marcado como `SUCCESS` en `sap_ingestion_batches`.

Ejecutar el proyecto dbt externo:

```bash
make dbt-build
```

Ejecutar la demo local para las cuatro tablas:

```bash
make demo
```

`make demo` ejecuta bootstrap, carga la fuente, extrae y carga `MARA`, `KNA1`, `VBAK` y `VBAP`, ejecuta `dbt build` en `../sap-glue-local-poc-dbt` y muestra resultados locales. Si el repositorio dbt hermano no existe, el comando falla con un mensaje claro.

Reiniciar el laboratorio local:

```bash
make clean
```

## Estructura

- `sap-simulator/`: esquema PostgreSQL y scripts de datos para tablas tipo SAP.
- `extractor-simulator/`: paquete Python para extraccion full-table a Parquet y manifiestos.
- `aws-local/`: scripts de bootstrap para S3 compatible y DynamoDB local.
- `orchestrator/`: paquete Python para carga RAW en DuckDB guiada por manifiestos.
- `config/tables.yml`: metadatos de extraccion de tablas.
- `scripts/`: puntos de entrada para demo, limpieza y visualizacion de resultados.
- `data/`: area local de datos generados, excluida de git salvo `.gitkeep`.

## Limitaciones

- No se incluyen credenciales reales.
- No se incluye integracion con sistemas SAP reales.
- No se incluye configuracion de extractores comerciales.
- No se incluye integracion con Snowflake.
- No se incluye proyecto dbt ni modelos dbt en este repositorio.
- No se hacen afirmaciones de seguridad, monitorizacion u orquestacion de nivel productivo.
- La logica de extractor soporta solo extraccion completa en la Fase 2.
- La extraccion incremental no esta implementada todavia.
- La carga del orquestador soporta solo tablas RAW locales guiadas por manifiestos.
- La idempotencia de lotes se controla por `batch_id` en almacenamiento local compatible con DynamoDB.
- La ejecucion de dbt es solo una llamada simple al repositorio hermano.
- Los recursos locales compatibles con AWS solo se validan para comportamiento de desarrollo local.

## Siguiente fase

La siguiente fase recomendada es reforzar el traspaso a transformaciones locales:

1. Anadir comprobaciones explicitas de profiles y paquetes dbt esperados.
2. Anadir comprobaciones ligeras de calidad sobre conteos RAW.
3. Anadir un resumen simple de resultados para tablas transformadas.
