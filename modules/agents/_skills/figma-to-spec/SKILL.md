---
name: figma-to-spec
description: Use when the user provides a Figma link (file, frame, or prototype) and wants a technical component spec. Drives Microsoft Edge via the browser-control skill to view the design, identifies visual components, and emits a multi-file spec emphasizing clean interfaces, composable controls, mock DOM snippets, and per-component markdown pages with mermaid nesting + data-contract diagrams. Triggers on "spec this figma", "review this figma design", "extract components from <figma url>", "build a component spec from figma".
metadata:
  author: miles
  version: "0.1"
compatibility: WSL2 host with the `browser-control` skill installed (provides bootstrap + Playwright bridge to the user's signed-in Microsoft Edge). The user must already have access to the target Figma file in that browser session.
---

# Figma → Technical Component Spec

Turn a Figma URL into a structured, opinionated component spec built on
top of the [`browser-control`](../browser-control/SKILL.md)
skill. The output is a directory of markdown + mermaid files that an
engineer (or another agent) can implement against.

## When to use this skill

- The user pastes a Figma link and asks for a "spec", "component
  breakdown", "design review", or "implementation plan".
- The user says "look at this figma and tell me what to build".
- Another skill or agent needs to convert a design into a tree of
  presenter/container components before writing code.

Do **not** use this skill for:

- Public design *systems* documentation (e.g. Material, Carbon) — just
  reference the upstream docs.
- Pixel-perfect CSS extraction — this skill is about component
  decomposition, not styling.

## Core conventions

These are the invariants every spec produced by this skill must follow.
Re-read [`references/conventions.md`](references/conventions.md) before
you start writing — it expands on each rule.

1. **Presenter at the leaf.** The lowest level of every nesting tree is
   a *presenter*: it takes data in via props and renders it. Presenters
   have **no** data-fetching, state machines, or routing — just props →
   DOM. Always.
2. **Containers compose presenters.** Anything above a leaf is a
   container: it owns data, state, or orchestration, and renders
   presenters (or other containers).
3. **Clean interfaces.** Every component has an explicit, typed input
   contract. Prefer narrow props over passing whole domain objects.
4. **Extract vs draw is a decision, not a default.** Call it out in the
   spec. If a visual region is only used once and has no internal
   variation, draw it inline in the parent's mock DOM and *do not*
   create a component file for it. The user will iterate with you on
   what gets extracted.
5. **Two mermaid diagrams per composite.** A nesting diagram (which
   components live inside this one) and a data-contract diagram (what
   shapes flow in and out). Presenters only need the contract diagram.
6. **One markdown page per extracted component.** No exceptions for
   "obvious" ones.

## Procedure

### 1. Load and bootstrap the browser bridge

Load the `browser-control` skill, then:

```bash
CDP_URL=$(bash "$AGENTS_SKILLS_DIR/browser-control/scripts/bootstrap.sh" | tail -n1)
```

### 2. Open the Figma URL

```bash
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/open_url.py" \
  "<figma-url>" --cdp-url "$CDP_URL"
```

If the resulting tab title is a Figma login page, use the `ask_user`
tool to ask the user to sign in (and pick the right team if
applicable), then continue.

Figma URLs come in three shapes; handle each:

| URL pattern                             | What to do                                   |
| --------------------------------------- | -------------------------------------------- |
| `…/file/<id>/…`                         | Whole file — ask which page/frame to spec.   |
| `…/file/<id>/…?node-id=<n>`             | Specific frame — start there.                |
| `…/proto/<id>/…?node-id=<n>`            | Prototype — switch to file view if possible. |

### 3. Capture the design surface

Figma's canvas is mostly `<canvas>`, so plain HTML scraping is useless.
You need screenshots. Capture each frame of interest:

```bash
python3 "$AGENTS_SKILLS_DIR/browser-control/scripts/capture_page.py" \
  --match "figma.com" \
  --out-dir ./spec/captures \
  --name <frame-slug> \
  --no-expand \
  --cdp-url "$CDP_URL"
```

Use `--no-expand` (Figma has no `aria-expanded` accordions worth
opening) and a generous `--wait-ms 1500` to let the canvas finish
rendering after zoom/scroll. If a frame is bigger than the viewport,
ask the user to **press `Shift+1`** in Figma to fit the frame, then
recapture.

Always view the resulting `.png` files yourself before writing the
spec — the screenshots are the source of truth for what components
exist.

### 4. Identify components (the analysis pass)

For each captured screenshot, list every distinct visual region. For
each region, decide:

- **Leaf or composite?** If it has internal layout with separable
  pieces, it's composite. Otherwise it's a leaf presenter.
- **Extract or draw inline?** Extract if (a) it repeats, (b) it has
  >1 visual state/variant, or (c) it has a clear single responsibility
  the parent shouldn't care about. Otherwise draw it inline.
- **Working name.** Use `PascalCase`. Suffix presenters with no
  suffix (e.g. `Avatar`, `Badge`); suffix containers with their role
  (`UserCard`, `OrderList`, `CheckoutPanel`).

Before producing files, present the candidate list to the user with
your extract/draw decision for each and ask them to confirm or revise.
The user expects to iterate here — that's the point.

### 5. Generate the spec tree

Write to `./spec/` (or the path the user requested). The layout is
fixed — see [`references/output-layout.md`](references/output-layout.md)
for the full description:

```
spec/
├── README.md              # overview, decisions, links to components
├── nesting.mmd            # top-level component tree (flowchart)
├── mock-dom.html          # whole-screen mock DOM, one frame per <section>
├── captures/              # source screenshots
└── components/
    ├── <Name>.md          # one per extracted component
    └── <Name>.mmd         # contract diagram for that component
```

### 6. Author each component page

Use [`references/component-template.md`](references/component-template.md)
verbatim as the starting point for every `components/<Name>.md`. Each
page must include, in order:

1. **Header** — name, classification (Presenter | Container), one-line
   purpose.
2. **Mock DOM** — a JSX-ish snippet showing the rendered shape. For
   containers, child components appear as `<ChildName />` placeholders
   linking to their page.
3. **Props / data contract** — a TypeScript-style `interface` block.
4. **Contract diagram** — embed `./<Name>.mmd` showing inputs, outputs,
   and (for containers) which children consume which slice of the
   props.
5. **Nesting** (containers only) — a second mermaid block listing the
   children and which are presenters vs containers.
6. **Variants / states** — bullet list, each linked to the screenshot
   region that motivated it.
7. **Open questions** — anything the design didn't answer (empty
   state, error state, loading state, i18n).

Mermaid templates for both diagram kinds are in
[`references/mermaid-patterns.md`](references/mermaid-patterns.md).

### 7. Author the top-level files

- `nesting.mmd` — a single `flowchart TD` showing the whole tree.
  Style presenter nodes differently from container nodes (see
  reference).
- `mock-dom.html` — one `<section data-frame="…">` per captured
  Figma frame, with the top-level container's mock DOM inside. This is
  the "whole screen at a glance" artifact.
- `README.md` — overview, a list of every component with one-line
  descriptions, and an explicit **Extract/Draw decisions** section
  recording what you chose *not* to extract and why. This is the
  record the user will want to push back on.

### 8. Hand off and iterate

Summarize for the user:

- How many components were extracted, split by Presenter vs Container.
- The Extract/Draw decisions section, called out explicitly.
- Any open questions from the per-component pages.

Then *stop and ask* whether to (a) extract something you drew inline,
(b) collapse something you extracted, or (c) proceed.

## Example: spec a single Figma frame

```
user: spec https://www.figma.com/file/abc123/?node-id=42-17
```

1. Load `browser-control`, run bootstrap → `CDP_URL`.
2. `open_url.py "<figma-url>" --cdp-url "$CDP_URL"`.
3. Title says "Figma" and the canvas is visible → user is signed in.
4. `capture_page.py --name frame-42-17 --out-dir ./spec/captures …`.
5. `view ./spec/captures/frame-42-17.png` — it's a user profile card
   with a header, an avatar, a name, an action menu, and three stat
   tiles.
6. Candidate components:
   - `ProfileCard` (Container) — owns the whole frame.
   - `Avatar` (Presenter) — image + status dot.
   - `IdentityBlock` (Presenter) — name + handle.
   - `ActionMenu` (Container) — opens a popover; extract.
   - `StatTile` (Presenter) — single value + label; repeats 3×.
   - Background gradient header → **draw inline** in `ProfileCard`,
     not extracted (used once, no variants).
7. Ask user to confirm the candidate list and the extract/draw call on
   the header.
8. Write `spec/README.md`, `spec/nesting.mmd`, `spec/mock-dom.html`,
   and `spec/components/{ProfileCard,Avatar,IdentityBlock,ActionMenu,StatTile}.md`
   + matching `.mmd` files.
9. Summarize, point out that `ActionMenu` is the only container child
   and ask whether to keep it that way.

## References

- [`references/conventions.md`](references/conventions.md) — full
  rationale for presenter/container split, extract-vs-draw heuristics,
  and naming.
- [`references/component-template.md`](references/component-template.md)
  — verbatim template for `components/<Name>.md`.
- [`references/mermaid-patterns.md`](references/mermaid-patterns.md) —
  nesting diagram and data-contract diagram templates.
- [`references/output-layout.md`](references/output-layout.md) — exact
  directory structure of the generated spec.
- [`references/figma-navigation.md`](references/figma-navigation.md) —
  Figma-specific tips: zoom-to-fit, frame URLs, pages vs frames.
