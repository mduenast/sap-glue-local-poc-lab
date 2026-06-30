"""Manifest utilities."""

from __future__ import annotations

from datetime import datetime


def build_manifest(
    *,
    table: str,
    source_table: str,
    mode: str,
    batch_id: str,
    load_date: str,
    files: list[dict[str, object]],
    total_rows: int,
    created_at: datetime,
) -> dict[str, object]:
    """Build the JSON-serializable extraction manifest."""
    return {
        "source_system": "SAP_SIM",
        "extractor": "EXTRACTOR_SIMULATOR",
        "table": table,
        "source_table": source_table,
        "mode": mode,
        "batch_id": batch_id,
        "load_date": load_date,
        "status": "ready",
        "format": "parquet",
        "files": files,
        "total_rows": total_rows,
        "created_at": created_at.isoformat().replace("+00:00", "Z"),
    }
