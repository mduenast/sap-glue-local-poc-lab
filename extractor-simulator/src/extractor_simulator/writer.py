"""Landing-zone writer placeholder utilities."""

from __future__ import annotations


class LandingZoneWriter:
    """Plans landing-zone output paths for future extracted files."""

    def plan_table_output(self, table_name: str, batch_id: str) -> str:
        # TODO: Write CSV or Parquet files to S3-compatible storage in a later phase.
        output_path = f"s3://sap-glue-local-landing/raw/{table_name}/batch_id={batch_id}/data.parquet"
        print(f"planned landing output table={table_name} path={output_path}")
        return output_path
