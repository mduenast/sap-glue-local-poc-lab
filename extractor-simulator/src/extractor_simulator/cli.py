"""Command-line entry point for the extractor simulator."""

from __future__ import annotations

import argparse

from extractor_simulator.config import load_table_config
from extractor_simulator.extractor import Extractor


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the local extractor simulator.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    extract_parser = subparsers.add_parser("extract", help="Run a placeholder extraction.")
    extract_parser.add_argument("--config", default="../config/tables.yml", help="Path to table config YAML.")
    extract_parser.add_argument("--batch-id", default="local-placeholder-batch", help="Batch identifier.")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.command == "extract":
        table_config = load_table_config(args.config)
        Extractor(table_config=table_config, batch_id=args.batch_id).run()
        return 0

    raise ValueError(f"Unsupported command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
