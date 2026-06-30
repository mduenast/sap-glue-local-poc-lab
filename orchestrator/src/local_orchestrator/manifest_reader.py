"""Manifest reading from the Floci S3-compatible service."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from urllib.parse import urlparse

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError


@dataclass(frozen=True)
class Manifest:
    batch_id: str
    table: str
    source_table: str
    mode: str
    format: str
    file_paths: tuple[str, ...]
    file_rows: tuple[int | None, ...]
    total_rows: int
    created_at: str


class ManifestReader:
    def __init__(self, bucket: str, endpoint_url: str, region_name: str) -> None:
        self.bucket = bucket
        self.client = boto3.client(
            "s3",
            endpoint_url=endpoint_url,
            region_name=region_name,
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "test"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "test"),
            config=Config(s3={"addressing_style": "path"}),
        )

    @classmethod
    def from_env(cls) -> "ManifestReader":
        return cls(
            bucket=os.getenv("LANDING_BUCKET", "sap-glue-local-landing"),
            endpoint_url=os.getenv("AWS_ENDPOINT_URL")
            or os.getenv("FLOCI_ENDPOINT_URL", "http://localhost:4566"),
            region_name=os.getenv("AWS_DEFAULT_REGION", "eu-west-1"),
        )

    def read_manifest_uri(self, manifest_s3_uri: str) -> Manifest:
        bucket, key = parse_s3_uri(manifest_s3_uri)
        try:
            response = self.client.get_object(Bucket=bucket, Key=key)
            payload = json.loads(response["Body"].read().decode("utf-8"))
        except (BotoCoreError, ClientError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"Failed to read manifest '{manifest_s3_uri}': {exc}") from exc
        return validate_manifest(payload)

    def find_latest_for_table(self, table: str) -> str:
        short_table = table.strip().upper()
        prefix = f"landing/sap/{short_table}/"
        try:
            response = self.client.list_objects_v2(Bucket=self.bucket, Prefix=prefix)
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to list manifests for table '{short_table}': {exc}") from exc

        manifests = [
            item
            for item in response.get("Contents", [])
            if item["Key"].endswith("/manifest.json")
        ]
        if not manifests:
            raise ValueError(f"No manifest found for table '{short_table}' under s3://{self.bucket}/{prefix}")

        latest = max(manifests, key=lambda item: item["LastModified"])
        return f"s3://{self.bucket}/{latest['Key']}"


def parse_s3_uri(uri: str) -> tuple[str, str]:
    parsed = urlparse(uri)
    if parsed.scheme != "s3" or not parsed.netloc or not parsed.path:
        raise ValueError(f"Expected an S3 URI like s3://bucket/key, got '{uri}'")
    return parsed.netloc, parsed.path.lstrip("/")


def validate_manifest(payload: dict[str, object]) -> Manifest:
    required = ["table", "batch_id", "files", "total_rows"]
    missing = [field for field in required if field not in payload]
    if missing:
        raise ValueError(f"Manifest is missing required field(s): {', '.join(missing)}")

    table = payload["table"]
    batch_id = payload["batch_id"]
    files = payload["files"]
    total_rows = payload["total_rows"]

    if not isinstance(table, str) or not table.strip():
        raise ValueError("Manifest field 'table' must be a non-empty string.")
    if not isinstance(batch_id, str) or not batch_id.strip():
        raise ValueError("Manifest field 'batch_id' must be a non-empty string.")
    file_uris, file_rows = _normalize_files(files)
    if not isinstance(total_rows, int):
        raise ValueError("Manifest field 'total_rows' must be an integer.")

    return Manifest(
        batch_id=batch_id,
        table=table.upper(),
        source_table=str(payload.get("source_table", f"sap_{table.lower()}")),
        mode=str(payload.get("mode", "full")),
        format=str(payload.get("format", "parquet")),
        file_paths=tuple(file_uris),
        file_rows=tuple(file_rows),
        total_rows=total_rows,
        created_at=str(payload.get("created_at", "")),
    )


def _normalize_files(files: object) -> tuple[list[str], list[int | None]]:
    if not isinstance(files, list) or not files:
        raise ValueError("Manifest field 'files' must be a non-empty list.")

    uris: list[str] = []
    rows: list[int | None] = []
    for item in files:
        if isinstance(item, str):
            uris.append(item)
            rows.append(None)
            continue
        if isinstance(item, dict) and isinstance(item.get("uri"), str):
            uris.append(item["uri"])
            row_count = item.get("rows")
            rows.append(row_count if isinstance(row_count, int) else None)
            continue
        raise ValueError("Manifest field 'files' must contain S3 URI strings or objects with a 'uri' field.")

    return uris, rows
