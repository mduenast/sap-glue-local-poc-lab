"""DuckDB RAW table loading."""

from __future__ import annotations

from datetime import UTC, datetime
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.parse import urlparse

import boto3
import duckdb
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from local_orchestrator.manifest_reader import Manifest


class DuckDBLoader:
    def __init__(self, duckdb_path: str) -> None:
        self.duckdb_path = duckdb_path
        endpoint_url = os.getenv("AWS_ENDPOINT_URL") or os.getenv("FLOCI_ENDPOINT_URL", "http://localhost:4566")
        self.s3_client = boto3.client(
            "s3",
            endpoint_url=endpoint_url,
            region_name=os.getenv("AWS_DEFAULT_REGION", "eu-west-1"),
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "test"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "test"),
            config=Config(s3={"addressing_style": "path"}),
        )

    def load_manifest(self, manifest: Manifest) -> int:
        if manifest.format.lower() != "parquet":
            raise ValueError(f"Unsupported manifest format '{manifest.format}'. Only parquet is supported.")

        target_table = f"raw_sap_{manifest.table.lower()}"
        loaded_at = datetime.now(UTC).isoformat().replace("+00:00", "Z")
        Path(self.duckdb_path).parent.mkdir(parents=True, exist_ok=True)

        with TemporaryDirectory(prefix="local-orchestrator-") as tmpdir:
            local_files = [
                (self._download_file(file_uri, Path(tmpdir)), file_uri)
                for file_uri in manifest.file_paths
            ]

            with duckdb.connect(self.duckdb_path) as connection:
                for local_path, source_uri in local_files:
                    select_sql = (
                        "select *, "
                        f"'{_sql_escape(manifest.batch_id)}' as _batch_id, "
                        f"'{_sql_escape(manifest.source_table)}' as _source_table, "
                        f"'{_sql_escape(loaded_at)}' as _loaded_at, "
                        f"'{_sql_escape(source_uri)}' as _file_name "
                        f"from read_parquet('{_sql_escape(str(local_path))}')"
                    )
                    if self._table_exists(connection, target_table):
                        connection.execute(f"insert into {target_table} {select_sql}")
                    else:
                        connection.execute(f"create table {target_table} as {select_sql}")

        return manifest.total_rows

    def _download_file(self, s3_uri: str, target_dir: Path) -> Path:
        bucket, key = _parse_s3_uri(s3_uri)
        target_path = target_dir / Path(key).name
        try:
            self.s3_client.download_file(bucket, key, str(target_path))
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to download '{s3_uri}': {exc}") from exc
        return target_path

    @staticmethod
    def _table_exists(connection: duckdb.DuckDBPyConnection, table_name: str) -> bool:
        result = connection.execute(
            "select count(*) from information_schema.tables where table_name = ?",
            [table_name],
        ).fetchone()
        return bool(result and result[0])


def _parse_s3_uri(uri: str) -> tuple[str, str]:
    parsed = urlparse(uri)
    if parsed.scheme != "s3" or not parsed.netloc or not parsed.path:
        raise ValueError(f"Expected an S3 URI like s3://bucket/key, got '{uri}'")
    return parsed.netloc, parsed.path.lstrip("/")


def _sql_escape(value: str) -> str:
    return value.replace("'", "''")
