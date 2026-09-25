#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/check-boundary.py
# Explicit path overrides also avoid Nix 2.26's Git-subdirectory relative-input
# ambiguity. Only synthetic data is used; no credentials/private repo required.
consumer_args=(--override-input nix-common "path:$PWD"
  --override-input consumer-data "path:$PWD/example/fixture-data" --no-write-lock-file)
nix eval --json ./example#consumerContract "${consumer_args[@]}"
nix flake check --no-build --no-write-lock-file
node --test modules/ai/extensions/_local/pi-scan-guard/test/*.test.mjs \
  modules/ai/extensions/_local/agent-browser-edge-bridge/test/*.test.mjs
if [[ ${1:-} == --build ]]; then
  nix build ./example#checks.x86_64-linux.consumer-wrapper "${consumer_args[@]}" --no-link
  nix build .#checks.x86_64-linux.pi-agent-eval --no-link --no-write-lock-file
fi
