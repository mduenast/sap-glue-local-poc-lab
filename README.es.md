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
- Herramientas compatibles con AWS CLI opcionales para comandos locales de S3 y DynamoDB contra `localhost:4566`

## Inicio rapido

```bash
make up
make bootstrap
make seed-sap
```

Esto arranca PostgreSQL 16 y el servicio local Floci, crea el bucket local de aterrizaje y la tabla de estado de lotes, y carga las tablas fuente tipo SAP.

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

Reiniciar el laboratorio local:

```bash
make clean
```

## Estructura

- `sap-simulator/`: esquema PostgreSQL y scripts de datos para tablas tipo SAP.
- `extractor-simulator/`: esqueleto Python para extraccion de ficheros y manifiestos.
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
- La logica de extractor no esta implementada en la Fase 1.
- La logica de orquestador y carga en DuckDB no esta implementada en la Fase 1.
- Los recursos locales compatibles con AWS solo se validan para comportamiento de desarrollo local.

## Siguiente fase

La siguiente fase recomendada es implementar un camino minimo de punta a punta:

1. Leer `config/tables.yml`.
2. Extraer cada tabla desde PostgreSQL a ficheros Parquet o CSV locales.
3. Escribir un manifiesto simple por lote de extraccion.
4. Cargar en DuckDB los ficheros indicados por los manifiestos.
5. Persistir estado basico de lote en local.
