# Extractor Simulator

This package implements the Phase 2 extractor simulator.

Current responsibilities:

- read table metadata from `config/tables.yml`
- connect to the local PostgreSQL source
- extract one configured table in full mode
- write data files to a local S3-compatible landing zone
- write a manifest for each extraction batch

Incremental extraction is intentionally not implemented yet.

## Example

```bash
python -m extractor_simulator.cli extract --config ../config/tables.yml --table VBAK --mode full
```
