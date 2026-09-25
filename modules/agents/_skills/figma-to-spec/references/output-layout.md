# Output layout

Every generated spec uses this exact directory structure. Tools and
follow-up skills depend on it.

```
spec/
├── README.md              # Navigation: components list, decisions,
│                          # open questions, links to nesting/mock-dom.
├── nesting.mmd            # Single flowchart: the whole component tree.
├── mock-dom.html          # Whole-screen mock DOM, one <section> per
│                          # captured Figma frame.
├── captures/              # Source-of-truth screenshots from Figma.
│   ├── frame-<slug>.png
│   ├── frame-<slug>.html  # Usually mostly <canvas>; keep for record.
│   └── frame-<slug>.txt
└── components/
    ├── <Name>.md          # Per-component page (template:
    │                      # component-template.md).
    └── <Name>.mmd         # Per-component contract diagram.
```

## File responsibilities

### `README.md`

The map. Sections, in order:

1. **Overview** — Figma source link(s) and which frames were specced.
2. **Component index** — flat table of every extracted component:
   `Name | Presenter/Container | One-line purpose | Link`.
3. **Extract/Draw decisions** — bullet list of every region you chose
   to draw inline instead of extracting, each with a one-sentence
   reason. This is the iteration surface.
4. **Open questions (cross-cutting)** — anything that spans more than
   one component: theming, a11y, i18n, loading/empty/error policy.
5. **Artifacts** — links to `nesting.mmd`, `mock-dom.html`,
   `captures/`.

### `nesting.mmd`

Single mermaid `flowchart TD` showing every extracted component as a
node, edges for parent → child. Style classes `presenter` and
`container` per `mermaid-patterns.md`. No prop labels here — keep it
structural.

### `mock-dom.html`

Plain HTML, one `<section data-frame="<slug>">` per captured frame.
Inside each section, the top-level component's JSX-ish mock DOM as
`<pre><code class="language-jsx">…</code></pre>`. The top of the file
links each section to its corresponding screenshot in `captures/`.

This is the artifact a reviewer skims to get the whole-screen picture
without opening every component page.

### `captures/`

Raw output of `browser-control/scripts/capture_page.py`. Do not
edit. Filename slugs should match the `data-frame` attribute used in
`mock-dom.html` for cross-reference.

### `components/<Name>.md` and `components/<Name>.mmd`

One pair per extracted component. Page format is fixed — use
[`component-template.md`](./component-template.md) verbatim. The
`.mmd` is the contract diagram, embedded by reference from the `.md`
and also openable standalone (useful for renderers that don't inline
mermaid).
