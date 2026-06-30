"""Batch-state placeholder."""

from __future__ import annotations


class BatchStateStore:
    """Tracks processed batches in a future implementation."""

    def is_processed(self, batch_id: str) -> bool:
        # TODO: Check local DynamoDB-compatible state in a later phase.
        print(f"planned batch-state lookup batch_id={batch_id}")
        return False

    def mark_processed(self, batch_id: str) -> None:
        # TODO: Persist processed state in a later phase.
        print(f"planned batch-state write batch_id={batch_id}")
