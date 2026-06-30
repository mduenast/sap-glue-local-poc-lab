"""Command-line entry point for the extractor simulator."""

from __future__ import annotations

import argparse
import sys

from extractor_simulator.config import find_table_config, load_table_config
from extractor_simulator.extractor import Extractor


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the local extractor simulator.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    extract_parser = subparsers.add_parser("extract", help="Extract one configured table to local S3.")
    extract_parser.add_argument("--config", default="../config/tables.yml", help="Path to table config YAML.")
    extract_parser.add_argument("--table", required=True, help="Configured table name or short name, for example VBAK.")
    extract_parser.add_argument("--mode", required=True, choices=["full"], help="Extraction mode. Phase 2 supports full only.")
    extract_parser.add_argument("--batch-id", default=None, help="Optional batch identifier.")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.command == "extract":
        table_configs = load_table_config(args.config)
        table_config = find_table_config(table_configs, args.table)
        Extractor(table_config=table_config, mode=args.mode, batch_id=args.batch_id).run()
        return 0

    raise ValueError(f"Unsupported command: {args.command}")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"extractor error: {exc}", file=sys.stderr)
        raise SystemExit(1)
