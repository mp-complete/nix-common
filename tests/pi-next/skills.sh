#!/usr/bin/env bash
set -euo pipefail
# Invoked in a Nix build sandbox; no real credentials or model calls.
script="$1/bin/pi-next"
probe="$2"
export HOME="$TMPDIR/home"
mkdir -p "$HOME" "$TMPDIR/project"
cd "$TMPDIR/project"
unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR XDG_CONFIG_HOME PI_OFFLINE
export PI_TELEMETRY=0

# Explicit wrapper skills must load in a fresh HOME even with discovery off.
if ! PI_NEXT_PROBE_RESULT=probe.json timeout 60 "$script" \
  --no-session --no-skills --extension "$probe" --print /pi-next-smoke \
  > output.log 2> errors.log; then
  cat output.log errors.log >&2
  exit 1
fi
cat errors.log
test ! -s errors.log
jq -e '.skills == ["mk-pi-extension"]' probe.json
