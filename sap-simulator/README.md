# SAP-like Source Simulator

This folder contains PostgreSQL SQL scripts for a generic SAP-like source schema.

## Tables

- `sap_mara`: material master-like data
- `sap_kna1`: customer master-like data
- `sap_vbak`: sales document header-like data
- `sap_vbap`: sales document item-like data

## Usage

The scripts are mounted into the PostgreSQL container through Docker Compose. Run:

```bash
make up
make seed-sap
```

`03_seed_incremental_changes.sql` is kept separate so future phases can simulate changed rows after an initial extract.
