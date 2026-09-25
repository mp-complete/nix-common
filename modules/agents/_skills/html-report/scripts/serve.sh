#!/usr/bin/env bash
# serve.sh — serve the reports directory over HTTP so the user can browse
# all reports in one place. Uses Java's bundled jwebserver (no Python needed).
#
# Usage:  serve.sh [port]        # default 7777
#         AGENT_REPORTS_DIR=...  # serve from a different root
set -euo pipefail

PORT="${1:-7777}"
ROOT="${AGENT_REPORTS_DIR:-$HOME/reports}"

if [ ! -d "$ROOT" ]; then
  echo "no reports directory at $ROOT; nothing to serve" >&2
  exit 1
fi

# Generate a quick index page listing all reports, newest first.
INDEX="$ROOT/.serve-index.html"
{
  echo '<!doctype html><meta charset=utf-8><title>reports</title>'
  echo '<style>body{font:14px/1.5 system-ui,sans-serif;max-width:900px;margin:32px auto;padding:0 20px;color:#1a1a1a}'
  echo 'h1{font:600 18px/1.2 system-ui;border-bottom:1px solid #d0d0d0;padding-bottom:6px}'
  echo 'ol{list-style:none;padding:0}li{padding:6px 0;border-bottom:1px solid #eee}'
  echo 'a{color:#1f6feb;text-decoration:none}a:hover{text-decoration:underline}'
  echo '.mono{font-family:ui-monospace,Menlo,monospace;color:#6e6e6e;font-size:12px}</style>'
  echo "<h1>Reports under <span class=mono>$ROOT</span></h1><ol>"
  find "$ROOT" -mindepth 1 -maxdepth 2 -name index.html -printf '%T@\t%p\n' 2>/dev/null \
    | sort -rn \
    | while IFS=$'\t' read -r ts path; do
        rel="${path#$ROOT/}"
        dir="$(dirname "$rel")"
        ts_h="$(date -d "@${ts%.*}" '+%Y-%m-%d %H:%M')"
        title="$(grep -oE '<title>[^<]+</title>' "$path" | head -1 | sed 's,</\?title>,,g')"
        echo "<li><a href=\"$rel\">${title:-$dir}</a> <span class=mono>· $ts_h · $dir</span></li>"
      done
  echo '</ol>'
} > "$INDEX"

echo "serving $ROOT on http://127.0.0.1:$PORT/" >&2
echo "index page: http://127.0.0.1:$PORT/.serve-index.html" >&2
exec jwebserver -b 127.0.0.1 -p "$PORT" -d "$ROOT" -o info
