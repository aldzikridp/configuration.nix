"""LLM plugin providing the `fetch_url` tool.

Ported from the equivalent aichat (https://github.com/sigoden/aichat) bash
tool script `fetch_url_via_curl.sh`, rewritten to use native Python
libraries instead of shelling out to curl + pandoc + sed.

The original script pipes curl through `pandoc` to convert HTML into
GitHub-Flavored Markdown, dropping divs/spans/raw HTML and inline image
tags. This Python port uses `trafilatura` to fetch the URL and extract
the main content as Markdown. For LLM consumption this is typically
*better* than the original — trafilatura strips navigation, footers,
sidebars, and other boilerplate that pandoc leaves in, giving the model
a cleaner, more focused page representation.

Install (pip):
    llm install -e /path/to/llm-fetch-url

Use:
    llm -T fetch_url "your question" --td
"""

from __future__ import annotations

import re

import llm
import trafilatura


__version__ = "0.1.0"


# Strip inline image tags (![alt](url)) — mirrors the original
# `sed -E 's/!\[[^]]*\]\([^)]*\)//g'` from the aichat script. Belt-and-
# suspenders: trafilatura's `include_images=False` should already drop
# images, but we keep this to preserve the original tool's no-images
# contract.
_IMAGE_TAG_RE = re.compile(r"!\[[^]]*\]\([^)]*\)")


def fetch_url(url: str) -> str:
    """Fetch a URL and extract its main content as Markdown.

    Uses `trafilatura` to fetch the page and extract the main content
    (article body, blog post, etc.) as Markdown. Boilerplate such as
    navigation bars, footers, sidebars, and ads is stripped
    automatically — this typically produces cleaner, more focused
    output for LLM consumption than a raw HTML-to-Markdown conversion.

    Inline image tags (`![alt](url)`) are also stripped to match the
    behaviour of the original aichat `fetch_url_via_curl.sh` tool.

    Args:
        url: The URL to fetch.
    """
    if not url:
        return "error: url must not be empty"

    # Fetch the page. trafilatura.fetch_url handles redirects,
    # compression, and encoding detection internally. Returns None on
    # failure (HTTP error, timeout, malformed URL, etc.).
    try:
        downloaded = trafilatura.fetch_url(url)
    except Exception as e:
        return f"error: failed to fetch {url!r}: {e}"

    if downloaded is None:
        return (
            f"error: failed to fetch {url!r} "
            "(HTTP error, timeout, DNS failure, or blocked by server)"
        )

    # Extract the main content as Markdown. Settings chosen to mirror
    # the original aichat behaviour:
    #   - output_format="markdown"  -> Markdown instead of plain text
    #   - include_links=True        -> preserve hyperlinks (pandoc does)
    #   - include_images=False      -> drop images (sed strip in original)
    #   - include_tables=True       -> preserve tables (pandoc does)
    try:
        result = trafilatura.extract(
            downloaded,
            output_format="markdown",
            include_links=True,
            include_images=False,
            include_tables=True,
        )
    except Exception as e:
        return f"error: failed to extract content from {url!r}: {e}"

    if not result:
        return f"error: no extractable content found at {url!r}"

    # Defensive image strip in case trafilatura's include_images=False
    # leaves any image tags in (it shouldn't, but the original tool
    # guaranteed no images, so we preserve that contract).
    result = _IMAGE_TAG_RE.sub("", result)

    return result


@llm.hookimpl
def register_tools(register):
    """Register the fetch_url tool with llm."""
    register(fetch_url)
