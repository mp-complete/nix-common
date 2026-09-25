# Figma navigation tips

Notes on driving Figma through `browser-control`. Figma is a heavy,
canvas-based app, so most "scrape the DOM" instincts are wrong here.

## URL shapes

| Pattern                                       | Means                         |
| --------------------------------------------- | ----------------------------- |
| `…/file/<fileId>/<slug>`                      | Whole design file.            |
| `…/file/<fileId>/<slug>?node-id=<n>-<m>`      | A specific frame in the file. |
| `…/design/<fileId>/<slug>?node-id=…`          | Newer "Design" URL form.      |
| `…/proto/<fileId>/<slug>?node-id=…`           | Prototype player (read-only). |
| `…/board/<fileId>/<slug>`                     | FigJam board, not a UI file.  |

If the URL is `proto/…`, try opening the corresponding `file/…` URL
(swap the path segment) so you can see frame names and layer trees.

If the URL is a `board/…` (FigJam), stop and ask the user — this skill
is for UI files, not whiteboards.

## What you can and cannot see

- **Yes:** the rendered pixels (via screenshot).
- **Yes:** the page name in the top bar.
- **No:** layer names, dimensions, fills, or any structured design
  data — those are inside the canvas and not in the DOM.

If you need a structured tree (layer names, sizes, fills), tell the
user — getting that out of Figma requires either the Figma REST API
(needs a personal access token) or the user manually exporting frames.
This skill does not do that today.

## Practical capture tips

1. Ask the user to **press `Shift+1`** (Fit to screen) on the target
   frame before each capture. Without this, big frames spill outside
   the viewport.
2. For multi-frame specs, ask the user to navigate to each frame in
   turn; capture between navigations.
3. Use a generous `--wait-ms 1500` to let the canvas re-render after
   any zoom/pan/page change.
4. Use `--no-expand`. Figma has no useful `aria-expanded` accordions.
5. Name captures with a meaningful slug (`frame-profile-card`,
   `frame-settings-modal`) not Figma's auto-generated IDs.

## When the screenshot is unusable

- Looks blurry → user has Figma zoomed out; ask them to fit-to-frame.
- Shows a sign-in form → user isn't authenticated in the CDP browser
  profile; have them sign in to Edge and recapture.
- Shows the file picker → URL points to the dashboard, not a file; ask
  for the specific file/frame URL.
- Shows a "Restricted" / "No access" page → user lacks permission to
  the file in this browser session; nothing this skill can do.
