# Local Orchestrator

This package implements the Phase 3 local orchestrator.

Current responsibilities:

- read extraction manifests from local S3-compatible storage
- maintain batch state in local DynamoDB-compatible storage
- load manifest-listed Parquet files into DuckDB RAW tables
- skip batches already marked `SUCCESS`

RAW tables are named `raw_sap_<lower_table>` and include technical columns `_batch_id`, `_source_table`, `_loaded_at`, and `_file_name`.

## Example

```bash
python -m local_orchestrator.cli process-latest --table VBAK
python -m local_orchestrator.cli process-manifest --manifest-s3-uri s3://sap-glue-local-landing/landing/sap/VBAK/load_date=YYYY-MM-DD/batch_id=BATCH/manifest.json
python -m local_orchestrator.cli show-results
```
