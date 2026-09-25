"""List all open tabs in the bridged Edge profile.

Usage:
  python3 list_tabs.py [--filter SUBSTR] [--cdp-url URL]

Prints one tab per line in the form:
  <index>\\t<url>\\t<title>
"""
import argparse
import sys

from _wbc import connect


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", help="Only list tabs whose URL contains this substring.")
    ap.add_argument("--cdp-url")
    args = ap.parse_args()

    with connect(args.cdp_url) as (_, ctx):
        for i, pg in enumerate(ctx.pages):
            if args.filter and args.filter not in pg.url:
                continue
            try:
                title = pg.title()
            except Exception:
                title = "<unavailable>"
            print(f"{i}\t{pg.url}\t{title}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
