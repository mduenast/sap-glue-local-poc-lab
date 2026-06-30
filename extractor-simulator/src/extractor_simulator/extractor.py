"""PostgreSQL to local S3 extraction workflow."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from uuid import uuid4

import psycopg
import pyarrow as pa
import pyarrow.parquet as pq

from extractor_simulator.config import TableConfig
from extractor_simulator.manifest import build_manifest
from extractor_simulator.writer import S3LandingZoneWriter


@dataclass
class Extractor:
    table_config: TableConfig
    mode: str
    batch_id: str | None = None

    def run(self) -> None:
        """Extract one table, write Parquet locally, then upload it and a manifest."""
        if self.mode != "full":
            raise ValueError("Phase 2 supports only --mode full.")

        batch_id = self.batch_id or self._new_batch_id()
        load_date = date.today().isoformat()
        writer = S3LandingZoneWriter.from_env()

        rows = self._fetch_rows()
        with TemporaryDirectory(prefix="extractor-simulator-") as tmpdir:
            parquet_path = Path(tmpdir) / "part-00001.parquet"
            self._write_parquet(rows, parquet_path)

            prefix = (
                f"landing/sap/{self.table_config.short_name}/"
                f"load_date={load_date}/batch_id={batch_id}"
            )
            parquet_key = f"{prefix}/part-00001.parquet"
            manifest_key = f"{prefix}/manifest.json"

            parquet_uri = writer.upload_file(parquet_path, parquet_key)
            manifest = build_manifest(
                table=self.table_config.short_name,
                mode=self.mode,
                batch_id=batch_id,
                files=[parquet_uri],
                total_rows=len(rows),
                created_at=datetime.now(UTC),
            )
            manifest_uri = writer.upload_json(manifest, manifest_key)

        print(f"Extracted table={self.table_config.name} rows={len(rows)}")
        print(f"Parquet: {parquet_uri}")
        print(f"Manifest: {manifest_uri}")

    def _fetch_rows(self) -> list[dict[str, object]]:
        columns = ", ".join(self.table_config.primary_key)
        order_clause = f" order by {columns}" if columns else ""
        sql = f"select * from {self.table_config.name}{order_clause}"

        try:
            with psycopg.connect(self._postgres_dsn()) as connection:
                with connection.cursor(row_factory=psycopg.rows.dict_row) as cursor:
                    cursor.execute(sql)
                    return list(cursor.fetchall())
        except psycopg.Error as exc:
            raise RuntimeError(
                f"Failed to extract table '{self.table_config.name}' from PostgreSQL: {exc}"
            ) from exc

    @staticmethod
    def _write_parquet(rows: list[dict[str, object]], path: Path) -> None:
        table = pa.Table.from_pylist(rows)
        pq.write_table(table, path)

    @staticmethod
    def _postgres_dsn() -> str:
        host = os.getenv("POSTGRES_HOST", "localhost")
        port = os.getenv("POSTGRES_PORT", "5432")
        db = os.getenv("POSTGRES_DB", "sap_source")
        user = os.getenv("POSTGRES_USER", "lab_user")
        password = os.getenv("POSTGRES_PASSWORD", "lab_password")
        return f"host={host} port={port} dbname={db} user={user} password={password}"

    @staticmethod
    def _new_batch_id() -> str:
        timestamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
        return f"{timestamp}-{uuid4().hex[:8]}"
