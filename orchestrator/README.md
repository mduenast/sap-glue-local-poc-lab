# Local Orchestrator

This package is a skeleton for a future local orchestrator.

Planned responsibilities:

- discover extraction manifests
- maintain minimal batch state
- load manifest-listed files into DuckDB
- expose simple local commands for demo runs

The first iteration does not implement real loading. CLI commands print the intended behavior and return successfully.

## Example

```bash
python -m local_orchestrator.cli load --manifest-root ../data/landing/manifests
```
