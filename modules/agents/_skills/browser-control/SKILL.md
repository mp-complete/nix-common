---
name: browser-control
description: Use to drive the user's signed-in Microsoft Edge (running on the Windows host) from inside WSL via Chrome DevTools Protocol. Bootstraps Edge + a TCP forwarder so Playwright in WSL can connect to the Windows browser, then exposes thin helpers to open URLs, list tabs, and capture pages (HTML / text / screenshot) without re-authenticating against AAD/MFA-protected sites. Trigger when the user wants to "browse from WSL", scrape a corp-internal site, screenshot a page that requires their existing browser session, or whenever another skill needs an authenticated headed browser on this WSL host. Other skills/agents can build on this one — see references/consuming.md.
metadata:
  author: miles
  version: "0.1"
compatibility: WSL2 on Windows; Microsoft Edge on Windows; a Windows Python (3.10+) reachable via PATH or at C:\Python3xx\python.exe; a Python in WSL with the `playwright` package and Chromium driver (e.g. a `nix-shell -p python3 python3Packages.playwright playwright-driver.browsers`).
---

# WSL Browser Control

Bridge WSL → Windows Edge over CDP so agents can drive the user's
*real, signed-in* browser without launching a fresh Chromium in Linux.

## When to use this skill

- The user asks to open / screenshot / scrape a website from WSL and the
  site requires Microsoft (AAD / MFA / corp) auth.
- Another skill or agent needs an authenticated headed browser on this
  host. **Load this skill first**, then have the consuming skill call
  the scripts here (see "Consuming this skill from other skills").
- The user mentions "Windows Edge", "drive Edge", "CDP", "scrape from
  WSL", "use my real browser".

Do **not** use this skill for public-web fetches — `web_fetch` is
cheaper and faster.

## Architecture in one line

`Linux Playwright → http://<win-host>:9223 → Win Python TCP forwarder → 127.0.0.1:9222 → Edge`

For why each hop exists, read
[`references/architecture.md`](references/architecture.md).

## Procedure

All scripts live in this skill's `scripts/` directory and are
self-contained.

### 1. Bootstrap (always do this first; idempotent)

```bash
CDP_URL=$(bash "$AGENTS_SKILLS_DIR/browser-control/scripts/bootstrap.sh" | tail -n1)
```

`bootstrap.sh` will:

1. Auto-detect Windows username, Edge executable, and a Windows Python.
2. Copy the TCP forwarder to Windows `%TEMP%` and start it (if not
   already running) via `powershell.exe Start-Process`.
3. Launch Edge with a dedicated profile (`User Data - CDP`) so the
   user's regular Edge windows are untouched.
4. Verify reachability and print the CDP URL on the **last stdout
   line** (everything else goes to stderr).

If the user hasn't signed in yet to whatever site you're targeting,
the Edge window will be on the login page. Use the `ask_user` tool to
ask them to sign in, then proceed.

### 2. Open or focus a tab

```bash
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/open_url.py" \
  "https://example.com/path" --cdp-url "$CDP_URL"
```

Output is `key=value` lines: `url=`, `title=`, `matched=` (true if it
re-used an existing tab matching the URL). Pass `--match SUBSTR` if the
URL you'd open differs from how you'd find an already-open tab.

### 3. Capture a page

```bash
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/capture_page.py" \
  --match "example.com/path" \
  --out-dir ./captures \
  --name example_capture \
  --cdp-url "$CDP_URL"
```

Writes `<name>.html`, `<name>.txt`, `<name>.png` into `--out-dir`.
Scrolls + best-effort expands `aria-expanded=false` accordions before
snapshotting; pass `--no-scroll` / `--no-expand` to skip those, or
`--wait-ms N` for extra settle time.

### 4. List tabs (introspection / debugging)

```bash
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/list_tabs.py" \
  --cdp-url "$CDP_URL" [--filter SUBSTR]
```

One tab per line, tab-separated: `<index>\t<url>\t<title>`.

## Consuming this skill from other skills / agents

There are two clean patterns; pick whichever fits your skill:

### Pattern A — Reference and shell out (recommended)

The consuming skill's SKILL.md tells the agent:

> Before using a browser, load the `browser-control` skill and run
> `bootstrap.sh` to get a `CDP_URL`. Then call the helper scripts in
> `$AGENTS_SKILLS_DIR/browser-control/scripts/` with that URL.

The agent loads both skills, runs bootstrap, then drives the helpers.
Skills stay loosely coupled — no Python imports across skills.

### Pattern B — Import the Python helper

If your skill ships its own Python that already has playwright:

```python
import sys, os
sys.path.insert(0, os.path.join(
    os.environ['AGENTS_SKILLS_DIR'], 'browser-control', 'scripts'
))
from _wbc import connect, open_or_focus, find_page

with connect() as (browser, ctx):
    page = open_or_focus(ctx, "https://example.com")
    ...
```

This pulls in `_wbc.py`'s `connect`, `find_page`, and `open_or_focus`
helpers. Stable across versions of this skill.

`AGENTS_SKILLS_DIR` is set by the `home/skills` module to
`~/.agents/skills`; both patterns work whether the skill is loaded by
Copilot CLI, Claude Code, or any other agent that honors that
convention.

## Example: "screenshot the docs page for foo-service"

```
1. bash: CDP_URL=$(bash $AGENTS_SKILLS_DIR/browser-control/scripts/bootstrap.sh | tail -n1)
2. bash: python3 $AGENTS_SKILLS_DIR/browser-control/scripts/open_url.py \
            "https://eng.example.com/docs/foo-service" --cdp-url "$CDP_URL"
   -> title="Sign in to eng.example.com"   # not signed in yet
3. ask_user: "Please sign in to Edge, then say done."
4. bash: python3 $AGENTS_SKILLS_DIR/browser-control/scripts/capture_page.py \
            --match "/docs/foo-service" --out-dir ./out --name foo --cdp-url "$CDP_URL"
5. view ./out/foo.png
6. Summarize.
```

## References

- [`references/architecture.md`](references/architecture.md) — why each
  hop in the bridge exists; useful for diagnosing weird failures.
- [`references/consuming.md`](references/consuming.md) — longer
  examples of consumption patterns and pitfalls.
- [`references/troubleshooting.md`](references/troubleshooting.md) —
  symptom → fix table for the bootstrap and helper scripts.

## Environment overrides

| Variable                    | Default                                                                |
| --------------------------- | ---------------------------------------------------------------------- |
| `WSL_BROWSER_DEBUG_PORT`    | `9222` — Edge CDP port on Windows-localhost                            |
| `WSL_BROWSER_FORWARD_PORT`  | `9223` — TCP forwarder port reachable from WSL                         |
| `WSL_BROWSER_WIN_USER`      | auto from `%USERNAME%`                                                 |
| `WSL_BROWSER_USER_DATA_DIR` | `C:\Users\<user>\AppData\Local\Microsoft\Edge\User Data - CDP`         |
| `WSL_BROWSER_EDGE_EXE`      | auto-detect (Program Files / Program Files (x86))                      |
| `WSL_BROWSER_PYTHON_EXE`    | auto-detect (PATH, then `C:\Python31{2,3,4}\python.exe`)               |
| `CDP_URL`                   | `http://<win-host>:<forward-port>` — override if running multiple bridges |
