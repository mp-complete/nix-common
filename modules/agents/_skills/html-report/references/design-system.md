# Design system

Information density and clarity over decoration. Color encodes
*meaning*, not mood. Type is a system stack, never a downloaded font.

## Palette

| Token         | Light       | Dark       | Meaning                          |
| ------------- | ----------- | ---------- | -------------------------------- |
| `--bg`        | `#FAFAFA`   | `#0E0F11`  | page background                  |
| `--surface`   | `#FFFFFF`   | `#16181B`  | cards / panels                   |
| `--fg`        | `#1A1A1A`   | `#E6E6E6`  | primary text                     |
| `--fg-soft`   | `#2E2E2E`   | `#C8C8C8`  | body text                        |
| `--muted`     | `#6E6E6E`   | `#8B8B8B`  | metadata, labels, axis ticks     |
| `--rule`      | `#D0D0D0`   | `#2A2D31`  | borders, table edges             |
| `--rule-soft` | `#E5E5E5`   | `#1F2125`  | subdued separators               |
| `--accent`    | `#1F6FEB`   | `#4493F8`  | links, focal numbers, emphasis   |
| `--ok`        | `#2DA44E`   | `#3FB950`  | success / pass / ship            |
| `--warn`      | `#BF8700`   | `#D29922`  | caution / at-risk                |
| `--err`       | `#CF222E`   | `#F85149`  | failure / blocked / incident     |
| `--info`      | `#0969DA`   | `#58A6FF`  | informational pill / annotation  |
| `--code-bg`   | `#F3F3F3`   | `#1A1D21`  | code background                  |

Dark mode auto-applies via `prefers-color-scheme`; manual override via
the header toggle and `localStorage`.

### Color discipline

- Color is *only* for semantic state. A neutral header gets no color.
- Don't introduce new colors per report. If something needs a state,
  use one of `ok / warn / err / info / accent`.
- Diff blocks use light tints of `--ok` (add) and `--err` (delete) —
  don't darken or invert.

## Type stack

```css
--sans:  ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
--serif: ui-serif, Georgia, "Times New Roman", Times, serif;
--mono:  ui-monospace, "JetBrains Mono", "SF Mono", Menlo, Consolas, "DejaVu Sans Mono", monospace;
```

System stacks only — no Google Fonts, no font CDNs, no `@font-face`.
The user's OS font is the right font.

### Hierarchy

| Where                                   | Family | Size | Weight | Notes                                  |
| --------------------------------------- | ------ | ---- | ------ | -------------------------------------- |
| body                                    | sans   | 14px | 400    | line-height 1.5                        |
| H1 (page title)                         | sans   | 26px | 600    | letter-spacing slightly tight          |
| H2 (section)                            | sans   | 18px | 600    | hairline rule below                    |
| H3 (sub-section)                        | sans   | 14px | 600    | UPPERCASE + 0.04em letter-spacing      |
| H4                                      | sans   | 13px | 600    | not uppercased                         |
| eyebrows, meta, labels                  | mono   | 11px | 500    | UPPERCASE + 0.06em letter-spacing      |
| code, mono cells, paths, ids            | mono   | 12.5px | 400  |                                        |
| table headers                           | mono   | 11px | 600    | UPPERCASE + 0.05em letter-spacing      |
| numeric table cells                     | mono   | 13px | 400    | tabular numerals (`font-variant-numeric: tabular-nums`) |

There is **no serif body text**. Serif headings are out by default
(the engineering-IDE aesthetic). If you ever want academic styling
(Tufte) we'll add a `--style=tufte` flag; not in scope for v0.1.

## Spacing

- Page padding: `28px` (inline), `32px` (top), `40px` (footer top).
- Section heading top margin: `36px`.
- Section heading bottom margin: `10px`, with a hairline rule.
- Card padding: `18px 22px`.
- Pill padding: `1px 7px`.
- Borders: `1px` everywhere. (No 1.5px Anthropic-style; for an
  IDE-density aesthetic, `1px` is correct.)

## Layout

Default content width: `980px`. Pass `--wide` (or
`{ "wide": true }`) for `1280px` when the report has lots of tables /
charts.

Sidebar nav: deliberately omitted in v0.1. The TOC at the top of the
page (two-column on wide screens) handles navigation without losing
horizontal space.

## Density invariants

- Tables: 6×10 padding, hairline rows, sticky header.
- `<details>` rows: 8×12 padding, no extra outer margin beyond
  `8px 0`.
- Card max width follows page max width, not its own.
- Paragraphs cap at `78ch` for readability; do *not* cap full-width
  blocks (tables, code, figures) — let them use the whole column.

## Print

The print stylesheet collapses to a clean monochrome layout:

- Hides the theme toggle and TOC.
- Removes max-width caps.
- Adds `(URL)` after every external link.
- Forces `details` open so the reader sees evidence on paper.

The reader can hit Cmd-P / Ctrl-P in the browser and get a usable PDF
with no extra config.
