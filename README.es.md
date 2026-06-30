# Laboratorio local de datos tipo SAP

Este repositorio contiene un esqueleto pequeno y seguro para publicacion de un laboratorio ejecutable en local. Simula:

- una fuente operacional tipo SAP usando PostgreSQL
- un extractor de estilo empresarial que escribira ficheros y manifiestos en una zona de aterrizaje compatible con S3
- un orquestador local que leera manifiestos y cargara datos en DuckDB

El proyecto es intencionadamente generico. No conecta con ningun sistema SAP real, no incluye configuracion de extractores comerciales y no implementa modelos dbt. dbt vivira en un repositorio separado en fases posteriores.

## Arquitectura

```text
Fuente tipo SAP en PostgreSQL
  -> simulador de extractor
  -> zona de aterrizaje compatible con S3 proporcionada por Floci
  -> orquestador local
  -> fichero analitico DuckDB
```

Esta primera iteracion solo define la estructura, el esquema de origen, datos de ejemplo, esqueletos de paquetes y puntos de entrada operativos.

## Prerrequisitos

- Docker y Docker Compose
- Make
- Python 3.11 o superior para desarrollo local de paquetes
- Herramientas compatibles con AWS CLI para comandos locales de S3 y DynamoDB

## Inicio rapido

```bash
make up
make bootstrap
make seed-sap
make extract
make load
make demo
```

Los targets son placeholders de bajo alcance. Fases posteriores completaran la extraccion, escritura de manifiestos, seguimiento de estado y carga en DuckDB.

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
- La logica de extraccion y carga queda como TODO para fases futuras.

## Siguiente fase

La siguiente fase recomendada es implementar un camino minimo de punta a punta:

1. Leer `config/tables.yml`.
2. Extraer cada tabla desde PostgreSQL a ficheros Parquet o CSV locales.
3. Escribir un manifiesto simple por lote de extraccion.
4. Cargar en DuckDB los ficheros indicados por los manifiestos.
5. Persistir estado basico de lote en local.
