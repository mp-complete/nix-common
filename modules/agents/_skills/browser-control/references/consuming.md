# Consuming browser-control from other skills and agents

This skill is intentionally narrow: bridge Edge, expose tab and capture
helpers, get out of the way. Higher-level skills layer their own
domain logic (IcM scraping, ADO PR review, OneNote screenshotting, …)
on top.

## The cross-skill contract

Every consuming skill should reach `browser-control` via
`$AGENTS_SKILLS_DIR` (set by the `home/skills` module to
`~/.agents/skills`). That env var is the public API — never hardcode
`~/.agents/skills/browser-control`; another agent runner may
relocate the dir.

The minimum any consumer must do:

```bash
# 1. Bootstrap once per task. Idempotent and cheap (<1s) on warm runs.
CDP_URL=$(bash "$AGENTS_SKILLS_DIR/browser-control/scripts/bootstrap.sh" | tail -n1)

# 2. From here, run any helper with --cdp-url "$CDP_URL".
```

If you skip step 1 and just call `open_url.py` cold, the helper still
works because `_wbc.py` auto-discovers the CDP URL — but Edge may not
be running yet, so the connection will fail. Always bootstrap first.

## Pattern A — pure shell-out (recommended for most skills)

Your skill's SKILL.md instructs the agent like:

> Before any browser action, ensure `browser-control` is loaded and
> run `bootstrap.sh` to get a `CDP_URL`. Then call:
>
>   ```
>   $AGENTS_SKILLS_DIR/browser-control/scripts/open_url.py
>   $AGENTS_SKILLS_DIR/browser-control/scripts/capture_page.py
>   $AGENTS_SKILLS_DIR/browser-control/scripts/list_tabs.py
>   ```
>
> Parse output as `key=value` lines.

The agent loads `browser-control` on first reference and the rest
flows naturally. **Skills stay loosely coupled** and your skill needs
no Python environment of its own.

## Pattern B — Python import

If your skill needs to do more than the canned helpers expose
(e.g., click a specific button, evaluate JS, intercept network
requests), import the shared helper and write a custom Python script
in *your* skill's `scripts/`:

```python
# my-skill/scripts/do_thing.py
import sys, os
sys.path.insert(0, os.path.join(
    os.environ['AGENTS_SKILLS_DIR'], 'browser-control', 'scripts'
))
from _wbc import connect, open_or_focus, find_page

with connect() as (browser, ctx):
    page = open_or_focus(ctx, "https://something.com")
    page.wait_for_load_state("networkidle")
    page.click("button.do-thing")
    print(f"result={page.inner_text('.result')}")
```

Run it inside an environment that has Playwright installed (same nix
shell or virtualenv that `browser-control`'s helpers run under).

Caveats:

- `_wbc.py` is *not* a guaranteed-stable API yet — pin the version if
  this matters. The three names guaranteed: `connect()`,
  `find_page(ctx, substr)`, `open_or_focus(ctx, url, match=None)`.
- Don't shadow `_wbc` in your own `scripts/` dir; pick a different name
  or use absolute imports.

## Pattern C — Agent files (`.agent.md`)

An agent that exists specifically to "drive my browser" can declare
this skill in its prompt context:

```yaml
---
name: corp-browser-agent
description: Browses the user's signed-in corp services.
tools: [bash, view, ask_user]
skills:
  - browser-control
---
```

(Exact frontmatter shape depends on your runner; the example matches
Copilot CLI's `.agent.md` convention.) The agent will load
`browser-control`'s SKILL.md as part of its context on every
invocation.

## Anti-patterns

- **Don't re-implement the bridge.** If you find yourself launching
  Edge or socat-equivalent, you're duplicating this skill.
- **Don't share tabs across simultaneous skills.** Tabs are mutable.
  If two skills race on the same tab, results are non-deterministic.
  Either serialize, or have each skill open its own tab with a unique
  query-string fingerprint.
- **Don't assume `CDP_URL` is hostnamed `localhost`.** It's a Windows
  host IP from `ip route` — different per machine, sometimes
  per-reboot. Always treat it as opaque.

## Migration from custom bridges

If you previously bundled your own bootstrap (e.g., the original
`icm-edge-capture` skill's `launch_edge.sh`), replace it with a call to
`browser-control/scripts/bootstrap.sh` and remove the duplicated
forwarder. The CDP URL contract is identical: the last line of stdout
is `http://<host>:<port>`.
