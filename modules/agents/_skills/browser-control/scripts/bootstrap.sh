#!/usr/bin/env bash
# Bootstrap: ensure a Windows-side Edge with CDP enabled is running, and that
# its debug port is reachable from WSL via a Windows-side TCP forwarder.
#
# Idempotent — safe to invoke from every consumer call.
#
# Output contract: on success, the FINAL LINE on stdout is the CDP URL
#   (e.g., "http://172.27.48.1:9223"). All other diagnostic output goes
#   to stderr, prefixed with "[wsl-browser]". Consumers should do:
#
#     CDP_URL=$(bootstrap.sh | tail -n1)
#
# Environment overrides (all optional; sensible defaults):
#   WSL_BROWSER_DEBUG_PORT     CDP port on Windows-localhost  (default 9222)
#   WSL_BROWSER_FORWARD_PORT   Forwarded port WSL can reach   (default 9223)
#   WSL_BROWSER_WIN_USER       Windows username               (auto-detect)
#   WSL_BROWSER_USER_DATA_DIR  Edge profile dir               (auto-derived)
#   WSL_BROWSER_EDGE_EXE       Path to msedge.exe             (auto-detect)
#   WSL_BROWSER_PYTHON_EXE     Windows Python                 (auto-detect)
set -euo pipefail

DEBUG_PORT="${WSL_BROWSER_DEBUG_PORT:-9222}"
FORWARD_PORT="${WSL_BROWSER_FORWARD_PORT:-9223}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORWARDER_SRC="$SCRIPT_DIR/cdp_forwarder.py"

log() { printf '[wsl-browser] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# --- 0. Sanity-check that we're in WSL ----------------------------------
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  die "This skill only works inside WSL2 on Windows."
fi
command -v powershell.exe >/dev/null 2>&1 || die "powershell.exe not on PATH (interop disabled?)"
command -v cmd.exe        >/dev/null 2>&1 || die "cmd.exe not on PATH (interop disabled?)"
command -v wslpath        >/dev/null 2>&1 || die "wslpath missing — non-WSL distro?"

# --- 1. Resolve Windows-side paths --------------------------------------
WIN_USER="${WSL_BROWSER_WIN_USER:-$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')}"
[[ -n "$WIN_USER" ]] || die "Could not determine Windows username."

USER_DATA_DIR="${WSL_BROWSER_USER_DATA_DIR:-C:\\Users\\${WIN_USER}\\AppData\\Local\\Microsoft\\Edge\\User Data - CDP}"

# Edge — try the two common install locations unless overridden
if [[ -z "${WSL_BROWSER_EDGE_EXE:-}" ]]; then
  for candidate in \
    "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe" \
    "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe"; do
    wsl_path=$(wslpath -u "$candidate" 2>/dev/null) || continue
    if [[ -x "$wsl_path" ]]; then EDGE_EXE="$candidate"; break; fi
  done
  : "${EDGE_EXE:?Could not locate msedge.exe — set WSL_BROWSER_EDGE_EXE}"
else
  EDGE_EXE="$WSL_BROWSER_EDGE_EXE"
fi

# Python on Windows — search common locations and PATH unless overridden
if [[ -z "${WSL_BROWSER_PYTHON_EXE:-}" ]]; then
  PYTHON_EXE=$(powershell.exe -NoProfile -Command \
    "Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source" 2>/dev/null | tr -d '\r\n')
  if [[ -z "$PYTHON_EXE" ]]; then
    for candidate in C:\\Python314\\python.exe C:\\Python313\\python.exe C:\\Python312\\python.exe; do
      wsl_path=$(wslpath -u "$candidate" 2>/dev/null) || continue
      if [[ -x "$wsl_path" ]]; then PYTHON_EXE="$candidate"; break; fi
    done
  fi
  [[ -n "$PYTHON_EXE" ]] || die "No Python found on Windows. Install one or set WSL_BROWSER_PYTHON_EXE."
else
  PYTHON_EXE="$WSL_BROWSER_PYTHON_EXE"
fi

WINDOWS_HOST=$(ip route show default | awk '/default/ {print $3; exit}')
[[ -n "$WINDOWS_HOST" ]] || die "Could not determine Windows host IP from default route."

log "Windows host=$WINDOWS_HOST user=$WIN_USER edge=$EDGE_EXE python=$PYTHON_EXE"

# --- 2. Resolve forwarder paths (we may or may not need to redeploy) ----
WIN_TEMP_RAW=$(cmd.exe /c 'echo %TEMP%' 2>/dev/null | tr -d '\r\n')
WIN_TMP_WSL=$(wslpath -u "$WIN_TEMP_RAW")
FORWARDER_WIN_PATH="$WIN_TEMP_RAW\\wsl_browser_cdp_forwarder.py"

# --- 3. Launch Edge (no-op if our profile is already running) ----------
log "Ensuring Edge is running (CDP on 127.0.0.1:$DEBUG_PORT)..."
powershell.exe -NoProfile -Command \
  "Start-Process -FilePath '$EDGE_EXE' -ArgumentList '--remote-debugging-port=$DEBUG_PORT','--user-data-dir=$USER_DATA_DIR','--no-first-run','--no-default-browser-check','about:blank'" \
  >/dev/null 2>&1 || true

log "Waiting for Edge CDP port on Windows..."
for _ in $(seq 1 30); do
  count=$(powershell.exe -NoProfile -Command \
    "(Get-NetTCPConnection -LocalPort $DEBUG_PORT -State Listen -ErrorAction SilentlyContinue | Measure-Object).Count" \
    2>/dev/null | tr -d '\r\n ')
  if [[ "$count" =~ ^[1-9] ]]; then break; fi
  sleep 1
done
[[ "$count" =~ ^[1-9] ]] || die "Edge CDP port $DEBUG_PORT never came up on Windows."

# --- 4. Ensure TCP forwarder is running ---------------------------------
log "Ensuring TCP forwarder (0.0.0.0:$FORWARD_PORT -> 127.0.0.1:$DEBUG_PORT)..."
existing=$(powershell.exe -NoProfile -Command \
  "(Get-NetTCPConnection -LocalPort $FORWARD_PORT -State Listen -ErrorAction SilentlyContinue | Measure-Object).Count" \
  2>/dev/null | tr -d '\r\n ')
if [[ ! "$existing" =~ ^[1-9] ]]; then
  # Only (re)deploy the script when we actually need to start a new
  # forwarder — otherwise the running python.exe holds the file open
  # on Windows and cp would fail.
  cp "$FORWARDER_SRC" "$WIN_TMP_WSL/wsl_browser_cdp_forwarder.py"
  powershell.exe -NoProfile -Command \
    "Start-Process -FilePath '$PYTHON_EXE' -ArgumentList '$FORWARDER_WIN_PATH','$FORWARD_PORT','$DEBUG_PORT' -WindowStyle Hidden" \
    >/dev/null 2>&1
fi

# --- 5. Verify reachability and emit the CDP URL on stdout --------------
for _ in $(seq 1 15); do
  if curl -s --max-time 1 "http://$WINDOWS_HOST:$FORWARD_PORT/json/version" >/dev/null 2>&1; then break; fi
  sleep 1
done
curl -s --max-time 2 "http://$WINDOWS_HOST:$FORWARD_PORT/json/version" >/dev/null \
  || die "CDP endpoint not reachable from WSL at http://$WINDOWS_HOST:$FORWARD_PORT"

log "CDP endpoint ready."
printf 'http://%s:%s\n' "$WINDOWS_HOST" "$FORWARD_PORT"
