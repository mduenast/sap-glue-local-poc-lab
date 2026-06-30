# Extractor Simulator

This package is a skeleton for a future extractor simulator.

Planned responsibilities:

- read table metadata from `config/tables.yml`
- connect to the local PostgreSQL source
- extract configured tables in full or incremental mode
- write data files to a local S3-compatible landing zone
- write a manifest for each extraction batch

The first iteration does not implement real extraction. CLI commands print the intended behavior and return successfully.

## Example

```bash
python -m extractor_simulator.cli extract --config ../config/tables.yml
```
