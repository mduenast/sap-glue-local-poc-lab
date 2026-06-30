"""Local orchestration pipeline skeleton."""

from __future__ import annotations

from dataclasses import dataclass

from local_orchestrator.batch_state import BatchStateStore
from local_orchestrator.duckdb_loader import DuckDBLoader
from local_orchestrator.manifest_reader import ManifestReader


@dataclass
class Pipeline:
    manifest_root: str
    duckdb_path: str

    def run(self) -> None:
        reader = ManifestReader(self.manifest_root)
        state_store = BatchStateStore()
        loader = DuckDBLoader(self.duckdb_path)

        manifests = reader.read_pending()
        for manifest in manifests:
            if state_store.is_processed(manifest.batch_id):
                continue
            loader.load_manifest(manifest)
            state_store.mark_processed(manifest.batch_id)

        print("Orchestrator skeleton completed. No files were loaded.")
