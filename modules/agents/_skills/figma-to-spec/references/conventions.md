# Conventions for Figma → Spec output

These are the rules every generated spec must follow. They exist so that
implementing components from this spec is mechanical and so iteration
between user and agent about "what to extract" stays cheap.

## The presenter / container split

Every component is one of:

### Presenter (leaf)

- Pure function from props → DOM.
- No fetching, no global state, no routing, no side effects.
- No knowledge of where its data came from.
- May have purely local UI state (hover, focus) — that's it.
- Easy to render in isolation in a storybook/sandbox with a literal
  props object.

If a candidate component does anything except render its props, it is
**not** a presenter — promote it to a container or split off the data
concern.

### Container

- Owns data: fetches, subscribes, derives.
- Owns orchestration: routes, opens dialogs, triggers actions.
- Renders presenters (or smaller containers) and passes them props.
- Does **not** draw anything substantial itself. If you find yourself
  writing complex markup in a container, that markup should become a
  presenter.

### The invariant

> The **lowest** node in any nesting tree is always a presenter.

If your nesting tree has a container as a leaf, you've missed a
decomposition — find the presenter inside it.

## Extract vs draw

For every visual region you can name, decide whether it becomes its own
component (extract) or stays as inline markup in its parent (draw).

**Extract when at least one is true:**

- The region appears more than once (same frame or different frames).
- The region has more than one visual variant or state (selected,
  disabled, error, empty, …).
- The region has a single, name-able responsibility that the parent
  shouldn't care about (e.g. "show a user's avatar with online status").
- The region is non-trivial to lay out (>~5 logical sub-elements) and
  would bloat the parent's mock DOM.

**Draw inline when all are true:**

- Single occurrence.
- Single visual state.
- The parent's reason to exist already implies this region (e.g. a
  decorative header gradient on the one card that has it).
- Removing it as a separate component would *not* make any other
  component simpler.

**Record the decision.** Every "draw inline" choice goes in the
`Extract/Draw decisions` section of the spec `README.md` with a
one-sentence reason. This is the section the user will push back on
first; make it scannable.

## Naming

- `PascalCase` for component names.
- Presenters get bare nouns: `Avatar`, `Badge`, `Chip`, `StatTile`.
- Containers get role suffixes that describe what they orchestrate:
  `UserCard`, `OrderList`, `CheckoutPanel`, `ProfileHeader`.
- Avoid generic suffixes like `…Component`, `…Wrapper`, `…View`.
- Mirror Figma layer names where they're already good; rename
  aggressively where they aren't (Figma layer hygiene varies).

## Props

- Prefer narrow primitive props (`name: string`, `count: number`) over
  passing whole domain objects.
- Containers may accept ID-like props (`userId: string`) and resolve
  them internally; presenters never do — they take the resolved data.
- Event props use `onX` naming: `onSelect`, `onDismiss`, `onSubmit`.
- Slot props (renderable children) use `…Slot` or `children`:
  `headerSlot?: ReactNode`.

## What to put on each page

Re-read [`component-template.md`](./component-template.md). The
required sections are non-negotiable; add more only if they earn their
place.

## What goes in `README.md`

The top-level spec README is the navigation document. It must include:

1. One-paragraph overview of what was specced (which Figma file/frames).
2. A flat list of every component with its classification and a
   one-line purpose. Link each to its page.
3. The **Extract/Draw decisions** section.
4. Open questions that span more than one component (cross-cutting
   states, theming, accessibility).
5. A link to `nesting.mmd` and `mock-dom.html`.
