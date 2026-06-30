"""DuckDB loading placeholder."""

from __future__ import annotations

from local_orchestrator.manifest_reader import Manifest


class DuckDBLoader:
    def __init__(self, duckdb_path: str) -> None:
        self.duckdb_path = duckdb_path

    def load_manifest(self, manifest: Manifest) -> None:
        # TODO: Load manifest-listed files into DuckDB in a later phase.
        print(
            "planned DuckDB load "
            f"database={self.duckdb_path} table={manifest.table_name} batch_id={manifest.batch_id}"
        )
