#!/usr/bin/env bash
set -euo pipefail
# Real resource loading in a build sandbox; no model, MCP, PTY or browser calls.
script="$1/bin/consumer-pi"
probe="$2"
export HOME="$TMPDIR/consumer home"
export XDG_CONFIG_HOME="$TMPDIR/consumer config"
mkdir -p "$HOME" "$TMPDIR/project"
cd "$TMPDIR/project"
unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR PI_OFFLINE
export PI_TELEMETRY=0

test -x "$script"
test ! -e "$1/bin/pi-next"
test ! -e "$1/bin/pi"
test ! -e "$1/lib/node_modules"
if ! PI_NEXT_PROBE_RESULT=probe.json timeout 60 "$script" \
  --no-session --no-skills --extension "$probe" --print /pi-next-smoke \
  > output.log 2> errors.log; then
  cat output.log errors.log >&2
  exit 1
fi
cat errors.log
test ! -s errors.log
jq -e --arg dir "$XDG_CONFIG_HOME/consumer-pi" '
  .agentDir == $dir
  and .offline == "1"
  and .mcpServers == []
  and (.skills | index("consumer-skill") != null)
  and (.skills | index("mk-pi-extension") != null)
  and (.skills | index("btw") != null)
  and (.commands | index("todos") != null)
  and (.commands | index("plannotator-review") != null)
  and (.skills | index("plannotator") != null)
  and (.appendedPrompt | contains("Independent consumer instructions."))
' probe.json || { cat probe.json >&2; exit 1; }
test ! -e "$XDG_CONFIG_HOME/pi-next"
test ! -e "$HOME/.pi/agent"
