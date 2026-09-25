"""Capture the currently-loaded content of a matching tab in the bridged Edge.

Scrolls the page in steps to trigger lazy-loading, attempts to expand any
collapsed sections (best-effort), then writes:
  <out_dir>/<name>.html        full DOM after rendering
  <out_dir>/<name>.txt         body inner_text
  <out_dir>/<name>.png         full-page screenshot

Usage:
  python3 capture_page.py --match SUBSTR --out-dir DIR --name NAME [--cdp-url URL]
                          [--no-scroll] [--no-expand] [--wait-ms N]

Prints (key=value):
  url=<tab URL>     title=<tab title>
  html=<path>       text=<path>      screenshot=<path>
"""
import argparse
import sys
from pathlib import Path

from _wbc import connect, find_page


SCROLL_JS = """async () => {
  await new Promise(resolve => {
    let total = 0;
    const dist = 400;
    const timer = setInterval(() => {
      const scroller = document.scrollingElement || document.body;
      const sh = scroller.scrollHeight;
      window.scrollBy(0, dist);
      total += dist;
      if (total >= sh - window.innerHeight + 200) {
        clearInterval(timer);
        resolve();
      }
    }, 200);
  });
}"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--match", required=True, help="Substring to find the tab.")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--name", required=True, help="Basename for output files.")
    ap.add_argument("--cdp-url")
    ap.add_argument("--no-scroll", action="store_true")
    ap.add_argument("--no-expand", action="store_true")
    ap.add_argument("--wait-ms", type=int, default=0, help="Extra wait before capture.")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    with connect(args.cdp_url) as (_, ctx):
        page = find_page(ctx, args.match)
        if page is None:
            print(f"error=no_tab match={args.match}", file=sys.stderr)
            print("open_tabs:", file=sys.stderr)
            for pg in ctx.pages:
                print(f"  - {pg.url}", file=sys.stderr)
            return 2

        page.bring_to_front()
        try:
            page.wait_for_load_state("networkidle", timeout=30000)
        except Exception:
            pass

        if not args.no_scroll:
            page.evaluate(SCROLL_JS)
            page.wait_for_timeout(1500)

        if not args.no_expand:
            for sel in (
                "button[aria-expanded='false']",
                "button:has-text('Show more')",
                "button:has-text('Expand')",
            ):
                for b in page.query_selector_all(sel):
                    try:
                        b.click(timeout=400)
                    except Exception:
                        pass
            page.wait_for_timeout(800)

        if args.wait_ms:
            page.wait_for_timeout(args.wait_ms)

        page.evaluate("window.scrollTo(0, 0)")
        page.wait_for_timeout(400)

        html_path = out_dir / f"{args.name}.html"
        text_path = out_dir / f"{args.name}.txt"
        png_path = out_dir / f"{args.name}.png"
        html_path.write_text(page.content())
        text_path.write_text(page.inner_text("body"))
        page.screenshot(path=str(png_path), full_page=True)

        print(f"url={page.url}")
        print(f"title={page.title()}")
        print(f"html={html_path}")
        print(f"text={text_path}")
        print(f"screenshot={png_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
