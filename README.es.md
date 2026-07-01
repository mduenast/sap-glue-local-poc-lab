# Laboratorio local de datos tipo SAP

Este repositorio contiene un esqueleto pequeno y seguro para publicacion de un laboratorio ejecutable en local. Simula:

- una fuente operacional tipo SAP usando PostgreSQL
- Floci como emulador local compatible con AWS expuesto en `localhost:4566`
- un simulador de extractor que escribe ficheros Parquet y manifiestos
- un orquestador local guiado por manifiestos que carga tablas RAW en DuckDB
- una llamada final opcional a un proyecto dbt separado clonado junto a este repositorio

El proyecto es intencionadamente generico. No conecta con ningun sistema SAP real, no incluye configuracion de extractores comerciales y no contiene modelos dbt. dbt vive en un repositorio separado.

## Arquitectura

```text
Fuente tipo SAP en PostgreSQL
  -> simulador de extractor
  -> servicio Floci compatible con S3
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

`make dbt-build` usa por defecto el binario dbt del entorno virtual del repositorio hermano:

```text
../sap-glue-local-poc-dbt/.venv/bin/dbt
```

Pasa `DUCKDB_PATH` como ruta absoluta a ese fichero DuckDB. El ejemplo de profile de dbt debe usar esa variable de entorno `DUCKDB_PATH`.

## Prerrequisitos

- Docker y Docker Compose
- Make
- Python 3.11 o superior

El laboratorio instala herramientas compatibles con AWS CLI localmente en `.venv/` con `make setup`; no hace falta un comando `aws` global.

## Configuracion del proyecto dbt hermano

Este repositorio no instala dbt automaticamente y no incluye modelos dbt. Crea el entorno dbt explicitamente en el repositorio dbt hermano:

```bash
cd ../sap-glue-local-poc-dbt
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e .
```

Si el proyecto dbt hermano usa un fichero de requirements en lugar de un paquete editable, instala ese fichero desde el repositorio hermano:

```bash
.venv/bin/python -m pip install -r requirements.txt
```

Desde este repositorio de laboratorio, `make dbt-build` usa por defecto:

```make
DBT_PROJECT_DIR ?= ../sap-glue-local-poc-dbt
DBT_BIN ?= $(DBT_PROJECT_DIR)/.venv/bin/dbt
```

Sobrescribe cualquiera de los dos valores si el proyecto hermano esta en otra ruta o si quieres usar otro ejecutable dbt. El proyecto dbt hermano debe gestionar su propio setup; este laboratorio no instala dbt.

```bash
make dbt-build DBT_PROJECT_DIR=../mi-proyecto-dbt
make dbt-build DBT_BIN=/ruta/absoluta/a/dbt
```

## Inicio rapido

```bash
make doctor
make setup
make up
make bootstrap
make demo
```

Esto comprueba los prerrequisitos locales, instala herramientas locales y dependencias Python del laboratorio, arranca PostgreSQL 16 y Floci, crea el bucket local de aterrizaje y la tabla de estado de lotes, carga las tablas fuente tipo SAP, extrae datos a Parquet con manifiestos, carga tablas RAW en DuckDB, ejecuta dbt desde el repositorio hermano y muestra resultados locales.

`make setup` crea:

```text
.venv/                         # herramientas locales del laboratorio, incluido awscli
extractor-simulator/.venv/     # dependencias del extractor
orchestrator/.venv/            # dependencias del orquestador
```

Puedes sobrescribir el binario compatible con AWS CLI si hace falta:

```bash
make bootstrap AWS_BIN=/ruta/absoluta/a/aws
```

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

Comprobar los recursos Floci:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3api list-buckets
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 dynamodb list-tables
```

Ejecutar una extraccion completa de la tabla de cabecera de ventas:

```bash
make extract TABLE=VBAK
```

Listar los artefactos subidos:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 ls \
  s3://sap-glue-local-landing/landing/sap/VBAK/ \
  --recursive
```

Leer el ultimo manifiesto:

```bash
LATEST_MANIFEST="$(AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 ls s3://sap-glue-local-landing/landing/sap/VBAK/ --recursive | awk '/manifest.json/ {print $4}' | tail -n 1)"
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test .venv/bin/aws --endpoint-url http://localhost:4566 s3 cp "s3://sap-glue-local-landing/${LATEST_MANIFEST}" -
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

`make demo` ejecuta bootstrap, carga la fuente, extrae y carga `MARA`, `KNA1`, `VBAK` y `VBAP`, llama al binario dbt de `../sap-glue-local-poc-dbt/.venv/bin/dbt` y muestra resultados locales. Si falta el repositorio dbt hermano o su entorno virtual, el comando falla con un mensaje claro y accionable.

Reiniciar el laboratorio local:

```bash
make clean
```

## Esquema tipo SAP

El simulador PostgreSQL expone cuatro tablas genericas tipo SAP:

- `sap_mara`: `mandt`, `matnr`, `mtart`, `matkl`, `meins`, `ersda`, `erdat`, `aedat`
- `sap_kna1`: `mandt`, `kunnr`, `name1`, `land1`, `ort01`, `erdat`, `aedat`
- `sap_vbak`: `mandt`, `vbeln`, `kunnr`, `audat`, `auart`, `vkorg`, `erdat`, `aedat`, `waers`, `waerk`, `netwr`
- `sap_vbap`: `mandt`, `vbeln`, `posnr`, `matnr`, `kwmeng`, `vrkme`, `waerk`, `netwr`, `erdat`, `aedat`

## Contrato de manifiesto

El extractor escribe `manifest.json` junto a cada fichero Parquet. El manifiesto incluye:

- `source_system: "SAP_SIM"`
- `extractor: "EXTRACTOR_SIMULATOR"`
- `table` y `source_table`
- `mode`, `batch_id`, `load_date`, `status`
- `format: "parquet"`
- `files`, como objetos con `uri` y `rows`
- `total_rows`
- `created_at`

El orquestador acepta esta forma de manifiesto y mantiene compatibilidad simple con manifiestos antiguos donde `files` era una lista de URIs.

## Estructura

- `sap-simulator/`: esquema PostgreSQL y scripts de datos para tablas tipo SAP.
- `extractor-simulator/`: paquete Python para extraccion full-table a Parquet y manifiestos.
- `aws-local/`: scripts de bootstrap para servicios Floci compatibles con S3 y DynamoDB.
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
- La idempotencia de lotes se controla por `table_name` y `batch_id` en el servicio Floci compatible con DynamoDB.
- La ejecucion de dbt es solo una llamada simple al repositorio hermano.
- Los recursos Floci solo se validan para comportamiento de desarrollo local.

## Siguiente fase

La siguiente fase recomendada es reforzar el traspaso a transformaciones locales:

1. Anadir comprobaciones explicitas de profiles y paquetes dbt esperados.
2. Anadir comprobaciones ligeras de calidad sobre conteos RAW.
3. Anadir un resumen simple de resultados para tablas transformadas.
