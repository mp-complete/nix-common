# Spec schema

The `build.mjs` assembler reads a single JSON spec and produces
`index.html`. This file documents every field.

## Top-level

```jsonc
{
  "title":   "string, required",          // page title and H1
  "slug":    "string, required",          // kebab-case, used in dir name + footer
  "lede":    "string, optional",          // short paragraph under H1
  "badge":   "string, optional",          // small text shown next to slug; default "report"

  "summary": { /* required, see below */ },

  "recommendations": [ /* optional, list of items */ ],
  "openQuestions":   [ /* optional, list of items */ ],
  "outOfScope":      [ /* optional, list of items */ ],

  "sections": [ /* required if you want any content; see below */ ],

  "dataFiles": [ /* optional, list of files to drop into ./data/ */ ],

  "meta": { /* recommended, see below */ }
}
```

`recommendations`, `openQuestions`, `outOfScope` accept either strings
or `{ "text": "...", "refs": ["src-..."] }` objects. Omit the field
entirely (or pass `[]`) to hide that section.

## summary (required)

```jsonc
{
  "question":   "string, required — verbatim restatement of what was asked",
  "context":    "string, required — what was investigated and how",
  "findings":   [
    "Plain string finding",
    { "text": "Finding with provenance",
      "refs": ["src-pr-4421", "src-file-orderwrite"] }
  ],
  "confidence": {
    "level":  "high" | "medium" | "low",
    "reason": "string, required — one sentence"
  }
}
```

`findings` are rendered as an ordered list. `refs` become superscript
`[id]` links jumping to entries in `meta.sources` with matching ids.

## sections

A section has a heading, a stable id, and an ordered list of blocks:

```jsonc
{
  "id":      "kebab-case, optional (auto-derived from heading)",
  "heading": "string, required",
  "blocks":  [ /* see references/components.md */ ],
  "html":    "string, optional — escape hatch for raw HTML, rendered before blocks"
}
```

See [`components.md`](./components.md) for the full block catalog.

## dataFiles

Drop arbitrary files into the report's `data/` subdirectory:

```jsonc
[
  { "name": "raw-traces.json",  "content": { /* JSON value */ } },
  { "name": "queries.sql",      "content": "SELECT ..." },
  { "name": "screenshot.png",   "path":    "/abs/path/to/screenshot.png" }
]
```

Reference them with normal relative links: `<a href="data/queries.sql">`.

## meta

```jsonc
{
  "model":      "string",     // e.g. "claude-sonnet-4.7"
  "agent":      "string",     // e.g. "crush", "opencode", "copilot-cli"
  "host":       "string",     // defaults to os.hostname()
  "cwd":        "string",     // defaults to process.cwd()
  "prompt":     "string",     // verbatim user prompt; shown in <details open>
  "generatedAt": "ISO-8601 string", // defaults to now
  "tools": [
    { "name": "grep",  "calls": 14, "summary": "ripgrep across services/order" },
    { "name": "bash",  "calls":  6, "summary": "ran perf scripts" },
    { "name": "browser-control.capture_page", "calls": 1 }
  ],
  "sources": [
    { "id": "src-pr-4421",
      "kind": "pr",
      "url":  "https://github.com/example/order/pull/4421",
      "title": "PR #4421 — add pessimistic lock",
      "note": "merged 2026-06-10",
      "accessed": "2026-06-15" },
    { "id": "src-file-orderwrite",
      "kind": "file",
      "path": "services/order/src/write.go",
      "line": 142,
      "note": "lock acquisition site" },
    { "id": "src-trace-1402",
      "kind": "url",
      "url": "https://traces.example.com/...",
      "title": "Trace bundle 14:02–14:08 UTC" },
    { "id": "src-shot-1",
      "kind": "screenshot",
      "path": "screenshots/grafana.png",
      "title": "p99 spike on Grafana" }
  ]
}
```

See [`appendix-metadata.md`](./appendix-metadata.md) for tips on
gathering this metadata cheaply inside Crush / OpenCode / Copilot CLI.

## Source kinds

Pick the right `kind` for each entry — the renderer uses it to choose
the right affordance (link target, pill, formatting):

| kind         | required fields            | renders as                                  |
| ------------ | -------------------------- | ------------------------------------------- |
| `url`        | `url`, `title` (optional)  | hyperlink with optional `accessed` date     |
| `file`       | `path`, `line` (optional)  | inline `<code>path:line</code>` reference   |
| `pr`         | `url`, `title` (optional)  | `pr` pill + hyperlink                       |
| `commit`     | `url`, `title` (optional)  | `commit` pill + hyperlink                   |
| `issue`      | `url`, `title` (optional)  | `issue` pill + hyperlink                    |
| `screenshot` | `path` or `url`            | `screenshot` pill + hyperlink (PNG/JPG)     |

For anything else use `kind: "url"` and put the descriptor in `note`.

## Ids and refs

- All source ids should start with `src-` to make them obvious in spec
  files.
- All section ids should be kebab-case derived from the heading.
- Findings, recommendations, open questions, out-of-scope items, and
  list items can all carry `refs: [...]` — keep the citations close
  to the claim.
- The runtime adds a brief yellow flash to the target element when
  any in-page `#anchor` link is clicked, so the reader can locate
  the cited evidence visually.
