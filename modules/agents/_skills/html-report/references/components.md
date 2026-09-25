# Block types

Every block goes inside a section's `blocks` array. The renderer picks
behavior by `type`. Unknown types are emitted as an HTML comment and a
warning to stderr.

The blocks below cover every common report need. If you need raw HTML,
use `{"type":"html","html":"..."}` or the section-level `html` field —
but reach for it last; the typed blocks give you consistent styling
for free.

## `p` — paragraph

```json
{ "type": "p", "text": "p99 write latency began rising at 14:02 UTC." }
```

If `text` starts with `<`, it is passed through unescaped, so you can
include inline `<code>`, `<a>`, `<strong>`, etc.

## `note` — italicized paragraph

```json
{ "type": "note", "text": "Numbers below are pre-cache; cache hits are excluded." }
```

Use sparingly — for a methodology aside or assumption disclosure.

## `list` — ordered or unordered

```json
{
  "type":    "list",
  "ordered": false,
  "items": [
    "Plain item",
    { "text": "Item with refs", "refs": ["src-pr-4421"] }
  ]
}
```

## `code` — code block with optional caption + path

```json
{
  "type":    "code",
  "lang":    "go",
  "caption": "Lock acquisition site",
  "path":    "services/order/src/write.go:142",
  "code":    "mu.Lock()\ndefer mu.Unlock()\n// ...\nresp, err := externalCall(ctx)\n"
}
```

The `lang` value must match an `hljs` language id from the bundled
set (see [`code-blocks.md`](./code-blocks.md)). The `path` shows up
right-aligned above the block; use `file:line` form.

## `diff` — unified diff block

```json
{
  "type":  "diff",
  "lines": [
    "@@ -140,6 +140,10 @@",
    " func (s *Service) Write(ctx) error {",
    "-    mu.Lock()",
    "-    defer mu.Unlock()",
    "-    resp, err := externalCall(ctx)",
    "+    resp, err := externalCall(ctx)",
    "+    mu.Lock()",
    "+    defer mu.Unlock()",
    " }"
  ]
}
```

Each line is classified by its first character (`+` add, `-` delete,
`@` hunk, anything else context) and styled accordingly.

## `table` — generic table

```json
{
  "type":     "table",
  "sortable": true,
  "tight":    false,
  "caption":  "Slowest 10 endpoints in last hour",
  "headers": [
    "endpoint",
    { "text": "p50 (ms)", "align": "right" },
    { "text": "p99 (ms)", "align": "right" },
    { "text": "RPS",      "align": "right" },
    { "text": "owner",    "align": "mono" }
  ],
  "rows": [
    ["/api/orders/write", 42,  812, 120, "order-team"],
    ["/api/inventory",     8,  104, 950, "stock-team"]
  ]
}
```

- Set `sortable: true` to make column headers click-to-sort
  (table-sort.js is auto-included when any table on the page uses it).
- Use `align: "right"` for numbers (right-aligned + tabular numerals);
  `align: "mono"` for code-shaped identifiers.
- A cell can also be `{ "html": "<span class=\"pill ok\">ok</span>" }`
  for rich content.

## `kv` — key/value definition list

```json
{
  "type": "kv",
  "items": [
    { "k": "Repo",       "v": "services/order",                "mono": true },
    { "k": "Commit",     "v": "a1b2c3d",                       "mono": true },
    { "k": "Investigated", "v": "2026-06-15 14:00 – 15:30 UTC" }
  ]
}
```

Renders as a two-column grid. Set `mono: true` for values that should
be in monospace.

## `details` — collapsible drilldown

```json
{
  "type":    "details",
  "id":      "drill-trace-bundle",
  "summary": "Full trace bundle 14:02–14:08",
  "where":   "trace-id 9f8a1bc2",
  "open":    false,
  "lang":    "json",
  "code":    "{ \"spans\": [ ... ] }"
}
```

Use one of:

- `html`   — raw HTML body.
- `code` + `lang` — a single code block as the body.
- `blocks` — a list of nested blocks (any of the types on this page).

`summary` is the always-visible row; `where` is right-aligned metadata
(file path, trace id, query name, etc.). Set `open: true` to make it
expanded by default.

This is the primary affordance for *drilldown data* — long log
excerpts, full SQL queries, full table dumps, raw JSON. **Default to
hiding bulky evidence here**, with the body prose summarizing it.

## `figure` — SVG / image / arbitrary embed

```json
{
  "type":    "figure",
  "id":      "fig-latency-spike",
  "num":     "1",
  "caption": "p99 write latency, 24h window",
  "svg":     "<svg viewBox=\"0 0 600 200\">...</svg>"
}
```

Or:

```json
{ "type": "figure", "src": "data/grafana.png", "alt": "Grafana p99 panel", "caption": "Grafana panel at 14:05 UTC" }
```

Or:

```json
{ "type": "figure", "html": "<video src=\"data/screencap.webm\" controls></video>", "caption": "Repro" }
```

Inline SVG is the right default for small, hand-drawn analytical
diagrams (1–8 series, ≤~20 points). For richer charts, use the
`chart` block (Vega-Lite).

## `chart` — Vega-Lite

```json
{
  "type":    "chart",
  "id":      "chart-p99",
  "num":     "2",
  "caption": "p99 write latency vs RPS, last 4h",
  "spec": {
    "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
    "data":   { "values": [{"t":0,"p99":120},{"t":1,"p99":480}] },
    "mark":   { "type": "line", "point": true },
    "encoding": {
      "x": { "field": "t", "type": "quantitative" },
      "y": { "field": "p99", "type": "quantitative" }
    },
    "width":  "container",
    "height": 220
  }
}
```

The renderer includes `vega-embed` automatically when any `chart`
block is present. See [`viz.md`](./viz.md) for copy-pasteable specs
covering the common analytical chart types.

## `callout` — colored sidebar callout (use rarely)

```json
{ "type": "callout", "tone": "open-questions", "text": "What happens under multi-region writes?" }
```

`tone` is one of `recommendations`, `open-questions`, `out-of-scope`.
Prefer the top-level optional sections for these; reserve `callout`
for in-line emphasis inside a body section.

## `html` — raw HTML escape hatch

```json
{ "type": "html", "html": "<aside>...</aside>" }
```

Use when none of the typed blocks fit and you're authoring something
one-off. Don't reach for this for things the typed blocks already do —
the typed blocks keep styling consistent across reports.
