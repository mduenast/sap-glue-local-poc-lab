"""Command-line entry point for the local orchestrator."""

from __future__ import annotations

import argparse

from local_orchestrator.pipeline import Pipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the local orchestrator skeleton.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    load_parser = subparsers.add_parser("load", help="Run a placeholder DuckDB load.")
    load_parser.add_argument("--manifest-root", default="../data/landing/manifests")
    load_parser.add_argument("--duckdb-path", default="../data/warehouse/local_lab.duckdb")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.command == "load":
        Pipeline(manifest_root=args.manifest_root, duckdb_path=args.duckdb_path).run()
        return 0

    raise ValueError(f"Unsupported command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
