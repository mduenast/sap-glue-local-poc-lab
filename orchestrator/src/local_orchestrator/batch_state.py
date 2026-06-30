"""Batch-state tracking in local DynamoDB-compatible storage."""

from __future__ import annotations

from datetime import UTC, datetime
import os

import boto3
from botocore.exceptions import BotoCoreError, ClientError


class BatchStateStore:
    """Tracks processed batches in local DynamoDB-compatible storage."""

    def __init__(self, table_name: str, endpoint_url: str, region_name: str) -> None:
        self.table_name = table_name
        self.client = boto3.client(
            "dynamodb",
            endpoint_url=endpoint_url,
            region_name=region_name,
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "test"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "test"),
        )

    @classmethod
    def from_env(cls) -> "BatchStateStore":
        return cls(
            table_name=os.getenv("BATCH_STATE_TABLE", "sap_ingestion_batches"),
            endpoint_url=os.getenv("AWS_ENDPOINT_URL")
            or os.getenv("FLOCI_ENDPOINT_URL", "http://localhost:4566"),
            region_name=os.getenv("AWS_DEFAULT_REGION", "eu-west-1"),
        )

    def is_success(self, batch_id: str) -> bool:
        item = self.get(batch_id)
        return item.get("status", {}).get("S") == "SUCCESS" if item else False

    def get(self, batch_id: str) -> dict[str, dict[str, str]] | None:
        try:
            response = self.client.get_item(
                TableName=self.table_name,
                Key={"batch_id": {"S": batch_id}},
            )
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to read batch state for '{batch_id}': {exc}") from exc
        return response.get("Item")

    def put_status(
        self,
        *,
        batch_id: str,
        table: str,
        status: str,
        manifest_s3_uri: str,
        message: str | None = None,
    ) -> None:
        now = datetime.now(UTC).isoformat().replace("+00:00", "Z")
        item = {
            "batch_id": {"S": batch_id},
            "table_name": {"S": table},
            "status": {"S": status},
            "manifest_s3_uri": {"S": manifest_s3_uri},
            "updated_at": {"S": now},
        }
        if message:
            item["message"] = {"S": message[:1000]}

        try:
            self.client.put_item(TableName=self.table_name, Item=item)
        except (BotoCoreError, ClientError) as exc:
            raise RuntimeError(f"Failed to write batch state for '{batch_id}': {exc}") from exc
