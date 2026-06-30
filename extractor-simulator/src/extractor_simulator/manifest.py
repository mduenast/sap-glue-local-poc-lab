"""Manifest-writing placeholder utilities."""

from __future__ import annotations

from extractor_simulator.config import TableConfig


class ManifestWriter:
    """Plans manifest entries for a future extraction batch."""

    def plan_manifest_entry(self, table: TableConfig, output_path: str) -> None:
        # TODO: Persist manifest JSON after file writing is implemented.
        print(
            "planned manifest entry "
            f"table={table.name} mode={table.extraction_mode} output={output_path}"
        )
