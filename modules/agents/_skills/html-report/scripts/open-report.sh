#!/usr/bin/env bash
# open-report.sh — open a generated report in the user's preferred browser.
# Usage:  open-report.sh <path-to-index.html>
#         open-report.sh latest          # opens $AGENT_REPORTS_DIR/latest
set -euo pipefail

ROOT="${AGENT_REPORTS_DIR:-$HOME/reports}"
target="${1:-latest}"

if [ "$target" = "latest" ]; then
  if [ ! -L "$ROOT/latest" ] && [ ! -d "$ROOT/latest" ]; then
    echo "no latest report at $ROOT/latest" >&2
    exit 1
  fi
  index="$ROOT/latest/index.html"
elif [ -d "$target" ]; then
  index="$target/index.html"
elif [ -f "$target" ]; then
  index="$target"
else
  # Try resolving inside the reports root.
  if [ -f "$ROOT/$target/index.html" ]; then
    index="$ROOT/$target/index.html"
  elif [ -f "$ROOT/$target" ]; then
    index="$ROOT/$target"
  else
    echo "could not find report: $target" >&2
    exit 1
  fi
fi

if ! [ -f "$index" ]; then
  echo "no index.html at: $index" >&2
  exit 1
fi

if [ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ] && command -v wsl-open >/dev/null 2>&1; then
  exec wsl-open "$index"
elif command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$index"
else
  echo "no opener found; open manually: file://$index"
  exit 0
fi
