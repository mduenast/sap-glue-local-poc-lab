#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${ORCHESTRATOR_PYTHON:-python}"

if [ -x "orchestrator/.venv/bin/python" ] && [ "${ORCHESTRATOR_PYTHON:-}" = "" ]; then
  PYTHON_BIN="orchestrator/.venv/bin/python"
fi

PYTHONPATH=orchestrator/src "${PYTHON_BIN}" -m local_orchestrator.cli show-results
