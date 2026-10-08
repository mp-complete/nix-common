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
node --test modules/ai/extensions/_local/pi-scan-guard/test/*.test.mjs
if [[ ${1:-} == --build ]]; then
  nix build ./example#checks.x86_64-linux.consumer-wrapper \
    ./example#checks.x86_64-linux.consumer-pi \
    ./example#checks.x86_64-linux.consumer-skills "${consumer_args[@]}" --no-link
  nix build .#checks.x86_64-linux.pi-agent-eval \
    .#checks.x86_64-linux.pi-next-api \
    .#checks.x86_64-linux.pi-next \
    .#checks.x86_64-linux.pi-next-skills \
    .#checks.x86_64-linux.pi-next-notify \
    .#checks.x86_64-linux.pi-next-coexistence --no-link --no-write-lock-file
fi
