# Code blocks

The renderer inlines highlight.js core (~125KB) plus a hand-picked set
of language grammars. All of it ships in the generated `index.html`,
so reports work offline.

## Bundled languages by default

```
nix typescript javascript bash python json yaml rust go clojure
diff markdown
```

Plus everything that ships in the highlight.js *common* bundle: bash,
c++, csharp, css, diff, go, graphql, ini, java, javascript, json,
kotlin, less, lua, makefile, markdown, objectivec, perl, php,
php-template, plaintext, python, python-repl, r, ruby, rust, scss,
shell, sql, swift, typescript, vbnet, wasm, xml, yaml.

(typescript, javascript, bash, python, json, yaml, rust, go, diff,
markdown are also explicitly listed above so they're guaranteed even
if highlight.js' "common" definition changes.)

## Overriding the language set

```bash
node "$AGENTS_SKILLS_DIR/html-report/scripts/build.mjs" /tmp/spec.json \
  --langs nix,typescript,python,clojure,sql,fennel
```

Any language id supported by highlight.js works. If a requested
language isn't pre-vendored in
`assets/vendor/langs/<lang>.min.js`, the renderer falls back to the
core bundle for that lang (which already covers most common ones).

To add a new language permanently, fetch it from jsDelivr:

```bash
curl -o "$AGENTS_SKILLS_DIR/html-report/assets/vendor/langs/<lang>.min.js" \
  "https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.10.0/languages/<lang>.min.js"
```

…then add `<lang>` to your `--langs` list.

## `code` block vs `diff` block

- **`code` block** — for showing a snippet of a file in its current
  state, or for command/output examples. Carries `lang`, optional
  `caption`, optional `path`. Highlighted by highlight.js at view
  time.

- **`diff` block** — for showing a *change*. Carries a `lines` array
  of unified-diff lines (`+`, `-`, `@@`, context). Each line is
  styled red/green/blue, no syntax highlighting of the content
  itself. If you want syntax-highlighted diffs, use a `code` block
  with `lang: "diff"` instead — but the dedicated `diff` block looks
  better for code-review-style output.

```jsonc
// code block (highlighted Go):
{
  "type": "code",
  "lang": "go",
  "path": "services/order/src/write.go:142",
  "code": "func (s *Service) Write(ctx context.Context) error {\n    mu.Lock()\n    defer mu.Unlock()\n    return s.external(ctx)\n}"
}

// diff block:
{
  "type": "diff",
  "lines": [
    "@@ -140,4 +140,5 @@",
    " func (s *Service) Write(ctx context.Context) error {",
    "-    mu.Lock()",
    "-    defer mu.Unlock()",
    "-    return s.external(ctx)",
    "+    err := s.external(ctx); if err != nil { return err }",
    "+    mu.Lock(); defer mu.Unlock()",
    "+    return nil",
    " }"
  ]
}
```

## Captions and paths

For a `code` block linked to a real file, set:

- `caption` — a one-line description of what the block shows.
- `path`    — the `file:line` reference. Renders right-aligned above
  the block in monospace muted color.

```jsonc
{
  "type":    "code",
  "lang":    "typescript",
  "caption": "Lock acquisition before external call",
  "path":    "services/order/src/write.ts:142",
  "code":    "..."
}
```

The caption row gives the reader context without forcing them to
parse the code; the path gives them a click target if you want it
hyperlinkable (wrap the path in raw HTML in `caption` if you need
that — uncommon).

## Long blocks

For anything over ~60 lines, put it in a `<details>` instead of an
inline `code` block. The reader rarely needs the full source; they
want the summary plus a way to expand it.

```jsonc
{
  "type":    "details",
  "summary": "Full Write() implementation after the fix",
  "where":   "services/order/src/write.go:140-180",
  "lang":    "go",
  "code":    "func (s *Service) Write(...) error { /* 40 lines */ }"
}
```

## When to skip highlighting

Set `lang: "plaintext"` (or omit `lang` entirely) for command output,
trace dumps, plain log lines — anything where syntax coloring would
mis-color random words. The block still renders in monospace with
hairline borders.
