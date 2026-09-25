# Conventions

The non-negotiable invariants for every report this skill produces.

## Structural

1. **Executive summary first**, with the four fixed fields
   (`question`, `context`, `findings`, `confidence`). No exceptions.
2. **Optional callout sections come next, in this order**:
   recommendations → open questions → out of scope. Each gets its
   own H2; never merge into one section.
3. **Run-metadata appendix is last**, always.
4. **Every section has a stable id** (kebab-case from heading).
5. **TOC is auto-generated** from sections — never hand-author.

## Content

1. **No emojis.** Not in headings, not in pills, not in body.
2. **No marketing tone.** No "exciting findings", no "Let's dive in",
   no "Hope this helps".
3. **No mascots, no decorative icons, no hero illustrations.**
4. **Color encodes meaning only.** Neutral content gets no color.
   The semantic palette is fixed: `ok` (green), `warn` (amber),
   `err` (red), `info` (blue), `accent` (blue, for links/numbers).
5. **No paragraph bigger than 78ch.** Hard cap. Tables, code blocks,
   and figures can use the full width.
6. **No filler.** Don't restate the question in three different ways
   before answering. Senior audience.

## Provenance

1. **Every finding has provenance.** If you can't cite where it
   came from, drop it or move it to open questions.
2. **`refs` go right on the claim** — at the end of the finding text
   or in the list item, not buried in prose.
3. **All sources land in `meta.sources`** with stable `src-` ids.
   Never cite from body content to a URL that isn't also a source
   entry.
4. **Drilldowns over prose dumps.** Long log excerpts, full SQL
   results, full diffs go in `<details>` (block type `details`), not
   inline.

## Honesty

1. **Confidence is real.** Use `low` when sources conflict or key
   files weren't accessible. The reader can handle "I don't know".
2. **Open questions exist.** If you finish a report with no open
   questions, double-check — almost every real investigation leaves
   something unresolved.
3. **Out of scope is explicit.** When the user asked for X and Y but
   you only did X, name Y in "out of scope" with a one-line reason.

## Determinism

1. **Stable section ids.** Override the auto-derived one if you need
   ids to match across runs.
2. **Stable source ids.** Use the same `src-pr-4421` across reports
   that reference the same PR.
3. **Sorted lists where order isn't semantic.** Alphabetize tool
   tables, source lists where order is arbitrary, etc.
4. **No timestamps in section bodies** unless they're part of the
   content (e.g. an incident timeline). Run timestamp lives in the
   appendix.

## Block discipline

1. **Use typed blocks** (`p`, `list`, `code`, `table`, `kv`,
   `details`, `figure`, `chart`, `diff`, `callout`) wherever they
   fit. Reach for `html` only as a last resort.
2. **Charts > 4 points get axes and titles.** Single-number "trend"
   indicators use sparkline SVGs in `figure` blocks, not Vega-Lite.
3. **Tables with > 20 rows get `sortable: true`.**
4. **Tables with > 80 rows go in `data/` as CSV** with a 10-row
   preview table in the body.

## Anti-patterns to avoid

- A 12-section report with one paragraph per section. Either go deep
  in fewer sections, or merge thin sections together.
- A finding with no `refs` and no inline citation. Untraceable.
- "More analysis needed" without saying what analysis. Open
  questions should be specific.
- Pasting an entire file as a `code` block. Use a `details` block
  for the full file and a `code` block for the relevant snippet.
- Asking the reader to scroll through a 5MB JSON dump in a `<pre>`.
  Drop it into `data/` and link.
- Three different chart libraries in the same report. Pick SVG or
  Vega-Lite and stay there.
