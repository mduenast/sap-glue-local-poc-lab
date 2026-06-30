"""Placeholder extraction workflow."""

from __future__ import annotations

from dataclasses import dataclass

from extractor_simulator.config import TableConfig
from extractor_simulator.manifest import ManifestWriter
from extractor_simulator.writer import LandingZoneWriter


@dataclass
class Extractor:
    table_config: list[TableConfig]
    batch_id: str

    def run(self) -> None:
        """Describe the intended extraction without moving data yet."""
        writer = LandingZoneWriter()
        manifest_writer = ManifestWriter()

        print(f"Extractor simulator batch: {self.batch_id}")
        for table in self.table_config:
            # TODO: Query PostgreSQL and write table data in a later phase.
            output_path = writer.plan_table_output(table_name=table.name, batch_id=self.batch_id)
            manifest_writer.plan_manifest_entry(table=table, output_path=output_path)

        print("Extraction skeleton completed. No source data was moved.")
