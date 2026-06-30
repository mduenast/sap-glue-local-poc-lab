"""Configuration loading for the extractor simulator."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class TableConfig:
    name: str
    primary_key: tuple[str, ...]
    extraction_mode: str
    incremental_column: str | None = None

    @property
    def short_name(self) -> str:
        return self.name.removeprefix("sap_").upper()


def load_table_config(path: str | Path) -> list[TableConfig]:
    """Load table extraction metadata from YAML."""
    config_path = Path(path)
    with config_path.open("r", encoding="utf-8") as handle:
        raw_config = yaml.safe_load(handle) or {}

    tables = raw_config.get("tables", [])
    return [
        TableConfig(
            name=table["name"],
            primary_key=tuple(table.get("primary_key", [])),
            extraction_mode=table.get("extraction_mode", "full"),
            incremental_column=table.get("incremental_column"),
        )
        for table in tables
    ]


def find_table_config(tables: list[TableConfig], requested_table: str) -> TableConfig:
    """Find a configured table by full name or SAP-like short name."""
    normalized = requested_table.strip().lower()
    candidates = {
        table.name.lower(): table
        for table in tables
    }
    candidates.update({table.short_name.lower(): table for table in tables})

    table = candidates.get(normalized)
    if table is None:
        available = ", ".join(sorted(table.short_name for table in tables))
        raise ValueError(f"Unknown table '{requested_table}'. Available tables: {available}")

    return table
