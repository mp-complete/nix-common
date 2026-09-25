# ADO PR Markdown — Syntax Reference

All examples below are verified to work in **PR descriptions and PR comments**. Things that only work in wiki/readme are called out explicitly.

## Headers

```markdown
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

Use H2 (`##`) as the top level inside a PR description — the PR title already acts as H1.

## Paragraphs and line breaks (the ADO gotcha)

ADO does **not** treat a single newline as a `<br>`. To force a soft line break inside a paragraph you must end the previous line with **two spaces** before the newline:

```markdown
First line, ends with two spaces.··
Second line, rendered on a new row.
```

(The `··` denotes two trailing spaces.) Without them, both lines collapse into one paragraph.

To start a new paragraph, use a blank line:

```markdown
First paragraph.

Second paragraph.
```

## Emphasis

| Style         | Markdown               |
| ------------- | ---------------------- |
| Italic        | `*text*` or `_text_`   |
| Bold          | `**text**` or `__text__` |
| Strikethrough | `~~text~~`             |

Combine freely: `~~**Removed milestone**~~`.

No underline syntax exists; `<u>` only works in wiki, not in PRs.

## Block quotes

```markdown
> Single-line quote.

> First line of a paragraph quote.
> Second line, same quote.

>> Nested quote.
>>> Deeper nest.
```

## Horizontal rules

A blank line, then three hyphens:

```markdown
above

---

below
```

## Lists

Ordered list — the publisher renumbers automatically, so it's fine (and common) to use `1.` for every item:

```markdown
1. First
1. Second
1. Third
```

Unordered list — `-` or `*`:

```markdown
- Apple
- Pear
- Plum
```

Nesting uses **three-space indentation** (or a tab):

```markdown
1. Outer
   - inner
   - inner
      - deeper
1. Outer
```

## Task lists (checklists)

```markdown
- [x] Spec approved
- [ ] Implementation
- [ ] Tests
- [ ] Docs
```

Reviewers can click the checkboxes directly in the rendered PR without editing the markdown. Do **not** put task lists inside a table — they won't render.

## Tables

```markdown
| Feature    | Status | Owner   |
|:-----------|:------:|--------:|
| Calculator | ✅     | alice   |
| Graphs     | ⏳     | bob     |
| Mail       | ❌     | carol   |
```

Rules:

- Column alignment is controlled by colons in the separator row: `:--` left, `:--:` center, `--:` right.
- Escape a literal pipe with `\|`.
- **No in-cell line breaks** in PRs. `<br/>` works in wiki but not here — prefer two narrower columns or a list outside the table.
- Don't put checklists or fenced code inside tables; use inline code spans only.

## Code

Inline:

```markdown
Run `pnpm test` before pushing.
```

Fenced block with a language tag for highlighting:

````markdown
```ts
export function add(a: number, b: number) {
  return a + b;
}
```
````

Common language tags: `bash`, `sh`, `ts`, `js`, `tsx`, `json`, `yaml`, `toml`, `md`, `csharp`, `python`, `go`, `rust`, `sql`, `xml`, `html`, `css`, `diff`. Full list: highlight.js languages.

### Suggestion blocks (PR comments only)

Inside an inline PR comment, a fenced block with the language `suggestion` renders as a one-click apply patch for the line(s) the comment is attached to:

````markdown
```suggestion
for i in range(A, B + 100, C):
```
````

## Links

```markdown
[Display text](https://example.com)
<https://example.com>          <!-- auto-link -->
https://example.com            <!-- also auto-links in PRs -->
```

Anchor link to a heading on the same rendered page:

```markdown
[Jump to changes](#changes)
```

Anchor IDs lowercase the heading and replace whitespace + most punctuation with `-`. Inspect the rendered HTML if unsure.

If you need to type a literal `#1234` without triggering the work-item linker, escape it: `\#1234`, or wrap in backticks `` `#1234` ``.

## Images

```markdown
![alt text](https://host/path/img.png)
![sized](./diagram.png =600x400)
![width only](./wide.png =600x)
```

- `=WxH` syntax sets the rendered size. Space before `=`, no space around `x`.
- External hosts must send CORS headers; ADO sets `crossorigin="anonymous"` on all external images.
- The simplest way to embed an image in a PR is to drag-and-drop or paste into the editor — ADO uploads it as an attachment and inserts the markdown for you.

## Emoji

```markdown
:+1: :tada: :smile: :rocket: :warning: :bug:
```

GitHub-compatible set, no GitHub custom emoji (`:bowtie:` etc.). Escape with `\:smile:` to display the literal text.

## Collapsible sections

Standard HTML `<details>` works in PRs. Keep a **blank line between the `<summary>` and the inner markdown**, otherwise the inner block gets interpreted as raw HTML and stops rendering:

```markdown
<details>
<summary>Repro steps</summary>

1. `pnpm i`
2. `pnpm dev`
3. Open the workspace switcher.

</details>
```

Multiple details blocks can be nested or stacked.

## Escaping special characters

Backslash-escape any of: `\` `` ` `` `*` `_` `{` `}` `[` `]` `(` `)` `#` `+` `-` `.` `!` `|` `>`.

```markdown
\# not a heading
\*not italic\*
\#1234 not a work-item link
```

For backticks in pathological cases, use the HTML entity `&#92;` for the backslash if escaping breaks rendering.

## Things that do NOT work in PR descriptions

- **Mermaid diagrams** — the ```` ```mermaid ```` block renders as plain code. Export to PNG/SVG and embed as an image.
- **KaTeX / math** (`$...$` / `$$...$$`) — wiki and Markdown widget only.
- **Underline** (`<u>`) — wiki only.
- **HTML beyond `<details>`/`<summary>`/`<br>`/basic inline tags** — much HTML is stripped or escaped. Don't rely on `<style>`, `<script>`, `<iframe>` (all forbidden), or layout tables.
- **Code-style attachments** (`.cs`, `.xml`, `.ps1`, …) — those can be attached to wiki pages but not as PR-comment attachments. Image and PDF attachments are fine.
- **`<br/>` inside table cells** — wiki only.
