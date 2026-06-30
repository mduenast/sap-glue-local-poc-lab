"""Manifest discovery placeholder."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Manifest:
    batch_id: str
    table_name: str
    file_paths: tuple[str, ...]


class ManifestReader:
    def __init__(self, manifest_root: str) -> None:
        self.manifest_root = manifest_root

    def read_pending(self) -> list[Manifest]:
        # TODO: Read manifest JSON files from the landing zone in a later phase.
        print(f"planned manifest scan root={self.manifest_root}")
        return []
