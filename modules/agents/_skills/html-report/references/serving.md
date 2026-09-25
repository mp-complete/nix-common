# Serving and viewing

## Where reports live

By default: `~/reports/<slug>-<YYYY-MM-DDTHH-MM>/`. Override per-host
by setting `AGENT_REPORTS_DIR` (in `home.sessionVariables` or a shell
rc).

Each report directory contains:

```
<slug>-<ts>/
├── index.html          # the report itself — fully self-contained
├── data/               # any dataFiles you declared (optional)
│   ├── ...
└── vendor/             # vendored asset originals (optional)
```

`index.html` doesn't *need* `data/` or `vendor/` to render — CSS, JS,
syntax highlighter, theme stylesheets, and the user prompt are all
inlined. The sibling dirs only exist so you can link to standalone
files (CSVs, JSON dumps, screenshots) from inside the report.

A symlink `$AGENT_REPORTS_DIR/latest` is updated on every build to
point at the most recent report.

## Opening a report

```bash
# the just-built one (script printed the path on its last line)
bash "$AGENTS_SKILLS_DIR/html-report/scripts/open-report.sh" /path/to/index.html

# the most recent report (works regardless of the slug)
bash "$AGENTS_SKILLS_DIR/html-report/scripts/open-report.sh" latest

# by slug, with or without the timestamp suffix
bash "$AGENTS_SKILLS_DIR/html-report/scripts/open-report.sh" order-write-lock-2026-06-15T14-30
```

On WSL the script uses `wsl-open`, which routes to the *Windows*
default browser (`Edge` if that's your Windows default). On native
Linux it uses `xdg-open`, which routes to the Linux default browser
(Firefox in your config).

For the build script, just pass `--open`:

```bash
node "$AGENTS_SKILLS_DIR/html-report/scripts/build.mjs" spec.json --open
```

## Browsing all reports

```bash
bash "$AGENTS_SKILLS_DIR/html-report/scripts/serve.sh"
# serves $AGENT_REPORTS_DIR on http://127.0.0.1:7777/
# index page: http://127.0.0.1:7777/.serve-index.html
```

The serve script uses Java's bundled `jwebserver` (already on PATH on
your NixOS hosts). It generates a static index page listing every
report newest-first with its title and timestamp, so you can quickly
find an old report without remembering its slug.

To serve on a different port:

```bash
bash "$AGENTS_SKILLS_DIR/html-report/scripts/serve.sh" 9090
```

This is the right tool when you want to skim multiple reports in a
review pass (e.g. catching up after a vacation, or scanning the
"what did I investigate last quarter" set).

## URL convention

Every report has the same stable anchors:

- `#executive-summary`
- `#recommendations` (if present)
- `#open-questions`  (if present)
- `#out-of-scope`    (if present)
- `#<section-id>` for each body section
- `#appendix-metadata`

Source references resolve to `#<src-id>` in the appendix; drilldowns
resolve to `#drill-<slug>` inside body sections. Both flash briefly
yellow when jumped to so the reader can find them visually.

## Print to PDF

Open in browser, hit `Ctrl-P` / `Cmd-P`. The print stylesheet:

- Removes the TOC and header controls.
- Forces all `<details>` open so evidence shows on paper.
- Adds `(URL)` suffixes after external links.
- Strips background colors for ink-saving.

Save as PDF for sharing with people who don't have access to your
filesystem.
