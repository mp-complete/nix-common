#!/usr/bin/env python3
"""Prevent accidental publication of source-environment material."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
paths = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
for relative in filter(None, paths):
    path = root / relative
    assert not relative.startswith(("secrets/", "modules/hosts/", "modules/work/", "memory/")), relative
    assert path.name != ".sops.yaml" and ".enc." not in path.name, relative
    assert "warehouse-ux-pr-review/" not in relative, relative
    assert not relative.startswith("overlays/agent-mcps/"), relative
    if path.suffix in {".nix", ".yaml", ".json", ".toml", ".lua", ".sh", ".md"}:
        text = path.read_text()
        for forbidden in ("ENC[AES256_GCM,", "icm-mcp-prod.azure-api.net", "72f988bf-86f1-41af-91ab-2d7cd011db47"):
            assert forbidden not in text, f"{relative}: forbidden environment material"
print("Public source boundary checks passed")
