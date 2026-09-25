"""Open a URL in the bridged Edge — or focus an existing matching tab.

Usage:
  python3 open_url.py <url> [--match SUBSTR] [--cdp-url URL]

Prints (key=value, one per line):
  url=<final tab URL>
  title=<tab title>
  matched=<true|false>   true if an existing tab was focused
"""
import argparse
import sys

from _wbc import connect, find_page, open_or_focus


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("--match", help="Substring to match against existing tab URLs (defaults to <url>).")
    ap.add_argument("--cdp-url")
    args = ap.parse_args()

    with connect(args.cdp_url) as (_, ctx):
        needle = args.match or args.url
        matched = find_page(ctx, needle) is not None
        page = open_or_focus(ctx, args.url, args.match)
        page.wait_for_timeout(1000)
        print(f"url={page.url}")
        print(f"title={page.title()}")
        print(f"matched={'true' if matched else 'false'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
