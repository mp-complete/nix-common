"""Shared utilities for browser-control Python helpers.

All helpers connect to the bridged Edge over CDP via Playwright.

Design notes for callers:
  - The CDP URL is auto-detected from the WSL default route + the
    WSL_BROWSER_FORWARD_PORT env var. Pass --cdp-url to override.
  - Tab matching is by URL substring. We don't require exact URL equality
    because IcM/ADO/etc. routinely re-write fragments and query strings.
  - All helpers print key=value lines on stdout so shell consumers can
    parse them with grep/cut without a JSON parser.
"""
from __future__ import annotations

import os
import subprocess
import sys
from contextlib import contextmanager
from typing import Optional

try:
    from playwright.sync_api import sync_playwright, Browser, BrowserContext, Page
except ImportError:
    sys.stderr.write(
        "ERROR: playwright is not importable in this Python.\n"
        "       Run helpers inside a shell that has playwright available\n"
        "       (e.g., a nix-shell with python3Packages.playwright).\n"
    )
    raise


def windows_host() -> str:
    out = subprocess.check_output(["ip", "route", "show", "default"], text=True)
    for tok in out.split():
        if tok.count(".") == 3:
            return tok
    raise RuntimeError("Could not determine Windows host IP from default route.")


def default_cdp_url() -> str:
    port = os.environ.get("WSL_BROWSER_FORWARD_PORT", "9223")
    return f"http://{windows_host()}:{port}"


def resolve_cdp_url(explicit: Optional[str]) -> str:
    return explicit or os.environ.get("CDP_URL") or default_cdp_url()


@contextmanager
def connect(cdp_url: Optional[str] = None):
    """Yields (browser, context). Context is Edge's default profile context."""
    url = resolve_cdp_url(cdp_url)
    with sync_playwright() as p:
        browser: Browser = p.chromium.connect_over_cdp(url)
        if not browser.contexts:
            raise RuntimeError(f"No browser contexts found at {url}")
        try:
            yield browser, browser.contexts[0]
        finally:
            browser.close()


def find_page(context: BrowserContext, url_substr: str) -> Optional[Page]:
    """Return the first page whose URL contains url_substr, else None."""
    for pg in context.pages:
        if url_substr in pg.url:
            return pg
    return None


def open_or_focus(context: BrowserContext, url: str, match_substr: Optional[str] = None) -> Page:
    """If a tab matching match_substr (or `url`) exists, focus it; else open a new one.

    Returns the page (focused). Does NOT wait for full load.
    """
    needle = match_substr or url
    existing = find_page(context, needle)
    if existing is not None:
        existing.bring_to_front()
        return existing
    page = context.new_page()
    page.goto(url, wait_until="domcontentloaded")
    return page
