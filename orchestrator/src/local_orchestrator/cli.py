"""Command-line entry point for the local orchestrator."""

from __future__ import annotations

import argparse
import os
import sys

from local_orchestrator.duckdb_loader import DuckDBLoader
from local_orchestrator.manifest_reader import ManifestReader
from local_orchestrator.pipeline import Pipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the local manifest-driven orchestrator.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    manifest_parser = subparsers.add_parser("process-manifest", help="Process one manifest S3 URI.")
    manifest_parser.add_argument("--manifest-s3-uri", required=True)
    manifest_parser.add_argument("--duckdb-path", default=os.getenv("DUCKDB_PATH", "./data/warehouse/local_lab.duckdb"))

    latest_parser = subparsers.add_parser("process-latest", help="Process the latest manifest for a table.")
    latest_parser.add_argument("--table", required=True)
    latest_parser.add_argument("--duckdb-path", default=os.getenv("DUCKDB_PATH", "./data/warehouse/local_lab.duckdb"))

    show_parser = subparsers.add_parser("show-results", help="Show RAW table row counts.")
    show_parser.add_argument("--duckdb-path", default=os.getenv("DUCKDB_PATH", "./data/warehouse/local_lab.duckdb"))

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.command == "process-manifest":
        Pipeline(manifest_s3_uri=args.manifest_s3_uri, duckdb_path=args.duckdb_path).run()
        return 0

    if args.command == "process-latest":
        manifest_s3_uri = ManifestReader.from_env().find_latest_for_table(args.table)
        print(f"Latest manifest: {manifest_s3_uri}")
        Pipeline(manifest_s3_uri=manifest_s3_uri, duckdb_path=args.duckdb_path).run()
        return 0

    if args.command == "show-results":
        show_results(args.duckdb_path)
        return 0

    raise ValueError(f"Unsupported command: {args.command}")


def show_results(duckdb_path: str) -> None:
    import duckdb

    if not os.path.exists(duckdb_path):
        print(f"DuckDB database does not exist yet: {duckdb_path}")
        return

    with duckdb.connect(duckdb_path) as connection:
        tables = connection.execute(
            "select table_name from information_schema.tables where table_name like 'raw_sap_%' order by table_name"
        ).fetchall()
        if not tables:
            print("No RAW tables found.")
            return
        for (table_name,) in tables:
            count = connection.execute(f"select count(*) from {table_name}").fetchone()[0]
            print(f"{table_name}: {count}")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"orchestrator error: {exc}", file=sys.stderr)
        raise SystemExit(1)
