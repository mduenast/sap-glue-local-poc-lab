"""S3 landing-zone writer."""

from __future__ import annotations

import json
import os
from pathlib import Path

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError


class S3LandingZoneWriter:
    """Uploads extracted files to the Floci S3-compatible landing bucket."""

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
    def from_env(cls) -> "S3LandingZoneWriter":
        return cls(
            bucket=os.getenv("LANDING_BUCKET", "sap-glue-local-landing"),
            endpoint_url=os.getenv("AWS_ENDPOINT_URL")
            or os.getenv("FLOCI_ENDPOINT_URL", "http://localhost:4566"),
            region_name=os.getenv("AWS_DEFAULT_REGION", "eu-west-1"),
        )

    def upload_file(self, source_path: Path, key: str) -> str:
        try:
            self.client.upload_file(str(source_path), self.bucket, key)
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to upload '{source_path}' to s3://{self.bucket}/{key}: {exc}") from exc
        return f"s3://{self.bucket}/{key}"

    def upload_json(self, payload: dict[str, object], key: str) -> str:
        body = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")
        try:
            self.client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=body,
                ContentType="application/json",
            )
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to upload manifest to s3://{self.bucket}/{key}: {exc}") from exc
        return f"s3://{self.bucket}/{key}"
