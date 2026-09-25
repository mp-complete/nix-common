# Provenance

Every report this skill produces is read by a senior engineer who will
follow up on anything that surprises them. They will only do that if
they can trivially trace each finding back to its source. Skimping on
provenance is the single highest way to make a report useless.

## The rule

> Every finding has at least one entry in `meta.sources`, and the
> finding's `refs` list cites it.

If you can't cite the source of a finding, drop the finding or move it
to the "open questions" section.

## Source kinds in detail

### `url`

External web references. Always include `title`. Include `accessed`
when the page might change (status dashboards, live metrics, wiki
pages); skip it for stable references (RFCs, published papers, tagged
GitHub releases).

```jsonc
{ "id": "src-rfc-7540",
  "kind": "url",
  "url":  "https://datatracker.ietf.org/doc/html/rfc7540",
  "title": "RFC 7540 — HTTP/2" }
```

### `file`

Local-repo file references. Use `path:line` style — matches the
`AGENTS.md` convention. Prefer specific line numbers over file-only
references; if a finding spans a function, link to the function's
first line and note the range in `note`.

```jsonc
{ "id": "src-file-orderwrite",
  "kind": "file",
  "path": "services/order/src/write.go",
  "line": 142,
  "note": "Write(ctx) method, lock acquisition site (lines 142-168)" }
```

The renderer formats this as inline `<code>services/order/src/write.go:142</code>`.

### `pr`, `commit`, `issue`

For PR / commit / issue references, the renderer adds a small pill
indicating the kind so the reader sees "PR" at a glance.

```jsonc
{ "id": "src-pr-4421",
  "kind": "pr",
  "url":  "https://github.com/example/order/pull/4421",
  "title": "PR #4421 — add pessimistic lock for OrderWrite",
  "note": "merged 2026-06-10 by @alice" }
```

Use the URL pattern your repo uses:

- GitHub: `https://github.com/<owner>/<repo>/pull/<n>` (and `/commit/<sha>`, `/issues/<n>`).
- Azure DevOps: `https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<n>` (or `/commit/<sha>`).

### `screenshot`

For evidence captured visually (Grafana panels, AAD-protected wikis,
Figma frames). Drop the file into the report via `dataFiles` so it
travels with `index.html`:

```jsonc
{
  "dataFiles": [
    { "name": "screenshots/grafana-p99.png", "path": "/tmp/grafana-p99.png" }
  ],
  "meta": {
    "sources": [
      { "id": "src-shot-grafana",
        "kind": "screenshot",
        "path": "data/screenshots/grafana-p99.png",
        "title": "p99 panel, 14:00–15:00 UTC" }
    ]
  }
}
```

For corp-internal or AAD-protected pages, capture screenshots with the
[`browser-control`](../../browser-control/SKILL.md) skill:

```bash
CDP_URL=$(bash "$AGENTS_SKILLS_DIR/browser-control/scripts/bootstrap.sh" | tail -n1)
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/capture_page.py" \
  --match "grafana.example.com" \
  --out-dir /tmp/shots --name grafana-p99 \
  --cdp-url "$CDP_URL"
```

Then add the resulting `.png` to `dataFiles` and a source entry.
`browser-control` is *not* a hard dependency of `html-report` — only
load it when a report genuinely needs an authenticated screenshot.

## Wiring findings to sources

The reader follows two paths:

1. **Top-down**: skim the executive summary, hit `[src-pr-4421]`,
   jump to the appendix to see what that source is, then click
   through to the PR.
2. **Section-down**: read a section, hit a `<details>` for the
   underlying data, see citations there.

Both paths must work. So:

- Every finding in `summary.findings` carries the `refs` of the
  sources that back it.
- Every section has either inline links (`<a href="#src-...">`) or
  blocks with `refs` for the claims it makes.
- Every drilldown that shows raw evidence (logs, SQL output, full
  diffs) gets a stable `id` so other parts of the report can link
  to it.

## Id conventions

- All source ids: `src-<kind>-<slug>`. Examples: `src-pr-4421`,
  `src-file-orderwrite`, `src-trace-1402`, `src-shot-grafana`.
- All drilldown ids: `drill-<slug>`. Examples: `drill-trace-bundle`,
  `drill-sql-full-result`.
- All section ids: kebab-case from heading (auto-derived; override in
  the spec if you need stability across runs).

Stable ids make report-to-report diffing possible. When the same
analysis runs a week later, the section anchors should match.

## Drilldown patterns

These are the patterns to reach for, in order of preference:

### 1. Inline `<details>` with the raw evidence

Best for log excerpts, SQL output, raw JSON, full diffs. The summary
line tells the reader what they'd expand into.

```jsonc
{ "type": "details",
  "summary": "Trace span 9f8a1bc2 — externalCall under lock",
  "where":   "trace-id 9f8a1bc2",
  "lang":    "json",
  "code":    "{ \"spans\": [...] }" }
```

### 2. `dataFiles` + a download link

For evidence too big to inline comfortably (>~100 lines or >~20KB).
Drop the file into `data/` and link to it from a block:

```jsonc
{ "type": "p",
  "text": "Full slow-query log: <a href=\"data/slow-queries.log\">slow-queries.log</a> (2.4MB)." }
```

### 3. External link

For evidence that lives in another system and shouldn't be duplicated
(PRs, dashboards, wiki pages). Source entry plus a citation.

### Anti-patterns

- Pasting 200 lines of log output directly into a `<pre>` block at the
  top level. Use `<details>` or `dataFiles`.
- Saying "see the database" without specifying the query that
  produced the cited rows. Include the query in a `code` block or
  `dataFiles` entry.
- Footnote-only citations with no `meta.sources` entry — the appendix
  must list every source so the reader can audit them in one place.
