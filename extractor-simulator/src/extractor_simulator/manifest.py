"""Manifest utilities."""

from __future__ import annotations

from datetime import datetime


def build_manifest(
    *,
    table: str,
    mode: str,
    batch_id: str,
    files: list[str],
    total_rows: int,
    created_at: datetime,
) -> dict[str, object]:
    """Build the JSON-serializable extraction manifest."""
    return {
        "table": table,
        "mode": mode,
        "batch_id": batch_id,
        "format": "parquet",
        "files": files,
        "total_rows": total_rows,
        "created_at": created_at.isoformat().replace("+00:00", "Z"),
    }
