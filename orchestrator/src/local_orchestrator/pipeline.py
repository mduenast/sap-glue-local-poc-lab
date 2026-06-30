"""Manifest-driven local orchestration pipeline."""

from __future__ import annotations

from dataclasses import dataclass

from local_orchestrator.batch_state import BatchStateStore
from local_orchestrator.duckdb_loader import DuckDBLoader
from local_orchestrator.manifest_reader import Manifest, ManifestReader


@dataclass
class Pipeline:
    manifest_s3_uri: str
    duckdb_path: str

    def run(self) -> None:
        reader = ManifestReader.from_env()
        state_store = BatchStateStore.from_env()
        loader = DuckDBLoader(self.duckdb_path)

        manifest = reader.read_manifest_uri(self.manifest_s3_uri)
        self.process_manifest(manifest, self.manifest_s3_uri, state_store, loader)

    @staticmethod
    def process_manifest(
        manifest: Manifest,
        manifest_s3_uri: str,
        state_store: BatchStateStore,
        loader: DuckDBLoader,
    ) -> None:
        if state_store.is_success(manifest.table, manifest.batch_id):
            print(f"Skipping table={manifest.table} batch_id={manifest.batch_id}; state is already SUCCESS.")
            return

        try:
            state_store.put_status(
                batch_id=manifest.batch_id,
                table=manifest.table,
                status="RECEIVED",
                manifest_s3_uri=manifest_s3_uri,
            )
            loaded_rows = loader.load_manifest(manifest)
            state_store.put_status(
                batch_id=manifest.batch_id,
                table=manifest.table,
                status="LOADED",
                manifest_s3_uri=manifest_s3_uri,
                message=f"Loaded {loaded_rows} row(s).",
            )
            state_store.put_status(
                batch_id=manifest.batch_id,
                table=manifest.table,
                status="SUCCESS",
                manifest_s3_uri=manifest_s3_uri,
                message=f"Loaded {loaded_rows} row(s).",
            )
        except Exception as exc:
            state_store.put_status(
                batch_id=manifest.batch_id,
                table=manifest.table,
                status="FAILED",
                manifest_s3_uri=manifest_s3_uri,
                message=str(exc),
            )
            raise

        print(f"Loaded batch_id={manifest.batch_id} table={manifest.table} rows={manifest.total_rows}.")
