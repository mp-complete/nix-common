---
name: html-report
description: Use when the user explicitly asks for an HTML report, a "report", a "writeup as html", "render this as a webpage", "html artifact", "html document", or similar — and the work involves enough output (multi-source research, code review, investigation, large data, drilldowns) that markdown in chat would lose information or be hard to skim. Produces a single self-contained `index.html` under `~/reports/` (overridable via `$AGENT_REPORTS_DIR`) with a mandatory executive summary, optional recommendations / open questions / out-of-scope sections, deep provenance (URLs, file:line refs, PRs/commits, screenshots), and an appendix recording the model, prompt, tools, and sources used. Optionally opens the result in the user's browser. Built for senior-engineer audiences — prioritizes information density and clarity over visual flourish.
metadata:
  author: miles
  version: "0.1"
compatibility: Requires node (>= 18) on PATH. Optional `wsl-open` on WSL, `xdg-open` on native Linux. The vega-lite chart block fetches Vega + Vega-Lite + vega-embed from jsdelivr at *view time* (online needed only when actually viewing such a report); everything else is fully inlined.
---

# html-report

Produce a single self-contained `index.html` for an analytical or
investigative result. Aimed at senior engineering readers: information
density and provenance first; decoration last.

## When to use this skill

Fire **only** when the user explicitly asks for HTML output. Trigger
phrases include:

- "give me an html report"
- "write this up as html", "render this as a webpage"
- "html this", "html artifact / document"
- "make me a report" *combined with* enough scope to justify HTML
  (multi-source, multi-section, drilldowns, embedded data, etc.)

Do **not** auto-fire for:

- A quick answer that fits in chat — stay in markdown.
- A single-file edit, a commit, a PR description, or other artifact
  whose canonical home is somewhere other than a browsable webpage.
- A short summary the user will copy into Slack/email — markdown is
  better there.

When in genuine doubt, ask before generating.

## Output contract

Every report this skill produces has, in order:

1. **Header** — title, generated-at timestamp, slug, theme toggle, link
   to the run-metadata appendix.
2. **Table of contents** — generated from sections.
3. **Executive summary** — *required*, fixed shape:
   - **Question** — verbatim restatement of what was asked.
   - **Context** — what was investigated; scope; time window; what
     tools/sources were used.
   - **Findings** — 3-7 bullet items, each linked (via `[refN]`
     superscripts) to the supporting evidence section below.
   - **Confidence** — `high | medium | low` + one-sentence reason.
4. **Recommendations** (optional, own section, only if there are any).
5. **Open questions** (optional, own section, only if there are any).
6. **Out of scope** (optional, own section, only if there are any).
7. **Body sections** — one section per topic. Use drilldown
   `<details>` for evidence the reader will only sometimes want.
8. **Appendix · Run metadata** — *required*:
   - Model, agent, host, generated-at, working dir, skill version.
   - Verbatim user prompt (collapsible, open by default).
   - **Tools used** — table of every tool the agent invoked while
     answering (tool name, call count, brief notes).
   - **Sources** — every URL, file, PR, commit, issue, and screenshot
     referenced from anywhere in the report, with stable `#refN`
     anchor ids that the body links to.

No emojis. No "made by an AI 🚀" framing. No mascots or hero
illustrations. No paragraph-of-throat-clearing intros.

## Procedure

### 1. Plan the report before writing JSON

Decide:

- **Slug** — short kebab-case identifier, e.g. `redux-epic-audit`,
  `pr-1234-review`, `lock-contention-investigation`.
- **Sections** — what topics, in what order. Each major topic is one
  section; supporting evidence goes into `<details>` inside it.
- **Provenance** — for each finding, list the URLs, file paths,
  PRs/commits, and screenshots that back it up. These become entries
  in `meta.sources` with stable ids the body cites via `refs`.
- **Confidence** — be honest. If two sources disagree or a key file
  wasn't accessible, that's `medium` or `low`.

If the user is asking you to investigate something *and* render the
result as HTML, **do the investigation first**, then assemble the
report. Don't interleave — the report is a write-up, not a journal.

### 2. Author the spec.json

Write a JSON file describing the report. The schema is in
[`references/spec-schema.md`](references/spec-schema.md). Drop it
anywhere convenient — typical pattern is `/tmp/<slug>.spec.json` or
the user's CWD.

Minimum viable spec:

```json
{
  "title": "Lock contention in OrderService write path",
  "slug": "order-write-lock-investigation",
  "lede": "A summary line shown under the title.",
  "summary": {
    "question": "Why are p99 OrderService writes spiking after 14:00 UTC?",
    "context": "Investigated traces, code, and recent deploys in the OrderService repo on 2026-06-15.",
    "findings": [
      { "text": "A new pessimistic lock was added in PR #4421.", "refs": ["src-pr-4421"] },
      { "text": "Lock window includes a 200ms external call.",   "refs": ["src-file-orderwrite"] }
    ],
    "confidence": { "level": "high", "reason": "Reproduced locally and confirmed via traces." }
  },
  "recommendations": [
    { "text": "Move the external call outside the lock; see proposed diff.", "refs": ["src-file-orderwrite"] }
  ],
  "sections": [
    {
      "heading": "Lock contention symptom",
      "blocks": [
        { "type": "p", "text": "p99 write latency began rising at 14:02 UTC, correlated with traffic, not a deploy." },
        { "type": "chart", "caption": "p99 write latency vs RPS, last 4h", "spec": { /* vega-lite spec */ } }
      ]
    }
  ],
  "meta": {
    "model":  "claude-sonnet-4.7",
    "agent":  "crush",
    "prompt": "Investigate why p99 OrderService writes are spiking after 14:00 UTC and write it up as an html report.",
    "tools":  [ { "name": "grep",  "calls": 14 }, { "name": "bash", "calls": 6 } ],
    "sources": [
      { "id": "src-pr-4421",       "kind": "pr",   "url": "https://github.com/example/order/pull/4421", "title": "PR #4421 add pessimistic lock" },
      { "id": "src-file-orderwrite", "kind": "file", "path": "services/order/src/write.go", "line": 142 }
    ]
  }
}
```

See [`references/spec-schema.md`](references/spec-schema.md) for the
full schema and [`references/components.md`](references/components.md)
for the catalog of block types (tables, code, diff, kv, details, chart,
figure, callout, etc.).

### 3. Build the report

```bash
node "$AGENTS_SKILLS_DIR/html-report/scripts/build.mjs" /tmp/<slug>.spec.json --open
```

Common flags:

- `--out <dir>` — explicit output directory. Default:
  `$AGENT_REPORTS_DIR/<slug>-<YYYY-MM-DDTHH-MM>/` (fall-back
  `~/reports/...`).
- `--open` — open the report in the user's default browser after
  build. On WSL this routes via `wsl-open` to the *Windows* default
  browser (where your bookmarks and sessions live), not the Linux one.
- `--langs nix,typescript,bash,...` — override the bundled
  highlight.js languages. Default is the common-stack set; see
  [`references/code-blocks.md`](references/code-blocks.md).
- `--wide` — switch to the 1280px content width (for data-heavy
  reports with lots of tables/charts).

The script:

- writes `index.html` (a single self-contained file with all CSS, all
  JS, and all highlighted language grammars inlined),
- copies any `dataFiles` from the spec into `<out>/data/`,
- updates `$AGENT_REPORTS_DIR/latest` to point at the new directory,
- prints the absolute path to `index.html` on its **last stdout
  line** (everything else goes to stderr).

### 4. Hand off to the user

Default response shape, kept short:

> Built: `~/reports/<slug>-...` &mdash; <one-sentence top finding>.
> Opens via `bash $AGENTS_SKILLS_DIR/html-report/scripts/open-report.sh latest`.

If `--open` was passed and the opener succeeded, you can skip the
"opens via..." line. Do not paste the HTML into chat. Do not summarize
the report's own contents back at the user — they're about to read it.

## Key rules

These hold across every report. Re-read
[`references/conventions.md`](references/conventions.md) when in doubt.

1. **Executive summary first, always.** No exceptions.
2. **Every finding has provenance.** If you can't cite where a finding
   came from, you don't have a finding — drop it or mark it as an
   open question.
3. **`refs` are cheap; use them liberally.** Body content links to
   `meta.sources` entries by id. The reader should never have to ask
   "where did that come from?".
4. **Drilldowns over prose paragraphs.** Long log dumps, full SQL
   results, full file contents go in `<details>` so the skim path
   stays tight. Use the `details` block type, not raw HTML.
5. **No decoration.** No emoji, no glyph icons that aren't
   information, no gradients, no rounded-corner hero cards. The
   palette has color *only* for semantic state (ok / warn / err /
   info / accent).
6. **Be honest about uncertainty.** Confidence is `high | medium |
   low`. Open questions get their own section. Conflicting sources
   get called out, not flattened.
7. **Determinism where possible.** Stable section ids, stable source
   ids, sorted lists where order isn't semantic. Two runs over the
   same data should produce diffable HTML.
8. **The reader is senior.** No "what is a database index?" asides.
   No listicles for the sake of listicles. Trust the audience.

## References

- [`references/spec-schema.md`](references/spec-schema.md) — the JSON
  spec schema in detail: every field, every block type's payload.
- [`references/components.md`](references/components.md) — catalog of
  block types with mock JSON for each. Read this before writing your
  first section.
- [`references/design-system.md`](references/design-system.md) — color
  palette, type stack, semantic state colors, spacing, when to use
  which.
- [`references/provenance.md`](references/provenance.md) — how to wire
  findings to evidence, source id conventions, screenshot capture via
  the `browser-control` skill.
- [`references/viz.md`](references/viz.md) — when to use inline SVG
  vs Vega-Lite vs nothing; copy-pasteable Vega-Lite specs for the
  common analytical chart types.
- [`references/code-blocks.md`](references/code-blocks.md) — which
  languages are bundled, how to add new ones, when to use `diff`
  blocks vs `code` blocks.
- [`references/appendix-metadata.md`](references/appendix-metadata.md)
  — what to record in `meta` so the appendix is useful (model, agent,
  prompt, tools, sources). Includes hints for the Crush / OpenCode /
  Copilot CLI environments.
- [`references/serving.md`](references/serving.md) — opening a report,
  serving the whole reports directory over HTTP, where files live.
- [`assets/sample.spec.json`](assets/sample.spec.json) — a complete,
  realistic spec you can copy and adapt.

## Scripts

- [`scripts/build.mjs`](scripts/build.mjs) — the assembler. Reads a
  spec, writes `index.html`. Vanilla Node, no npm deps.
- [`scripts/open-report.sh`](scripts/open-report.sh) — opens a report
  in the user's default browser (`wsl-open` on WSL, `xdg-open`
  elsewhere). Accepts a path, a slug, or `latest`.
- [`scripts/serve.sh`](scripts/serve.sh) — serves
  `$AGENT_REPORTS_DIR` over HTTP via `jwebserver` and generates an
  index page listing every report newest-first.

## Environment

| Variable             | Default          | Meaning                                         |
| -------------------- | ---------------- | ----------------------------------------------- |
| `AGENT_REPORTS_DIR`  | `~/reports`      | Where reports are written and `latest` lives.   |
| `AGENTS_SKILLS_DIR`  | `~/.agents/skills` | Skill root; set by the `home/skills` module.   |
