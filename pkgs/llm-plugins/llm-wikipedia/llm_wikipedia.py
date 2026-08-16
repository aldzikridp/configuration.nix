"""LLM plugin providing the `search_wikipedia` tool.

Ported from the equivalent aichat (https://github.com/sigoden/aichat) bash
tool script `search_wikipedia.sh`.

Install:
    llm install -e /path/to/llm-wikipedia

Use:
    llm -T search_wikipedia "your question" --td
"""

from __future__ import annotations

import json
import urllib.parse
import urllib.request

import llm


__version__ = "0.1.0"


# Wikipedia's API blocks the default Python-urllib User-Agent with HTTP 403,
# so we send a descriptive one as required by their API policy:
# https://meta.wikimedia.org/wiki/User-Agent_policy
_WIKIPEDIA_USER_AGENT = (
    f"llm-wikipedia/{__version__} "
    "(https://github.com/simonw/llm; contact: user@example.com) "
    "python-urllib"
)


def _http_get_json(url: str) -> dict:
    """GET a URL and return the parsed JSON. Sends a descriptive User-Agent
    so Wikipedia's API doesn't 403 us."""
    req = urllib.request.Request(url, headers={"User-Agent": _WIKIPEDIA_USER_AGENT})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def search_wikipedia(query: str) -> str:
    """Search Wikipedia for a query.

    Use this to get detailed information about a public figure, an
    interpretation of a complex scientific concept, or in-depth
    connectivity of a significant historical event. Returns the lead
    section (intro) of the top English Wikipedia search hit for the
    query, as plain text.

    Args:
        query: The query to search for.
    """
    if not query:
        return "error: query must not be empty"

    base_url = "https://en.wikipedia.org/w/api.php"
    encoded_query = urllib.parse.quote(query)

    # Step 1: search Wikipedia for the best matching article.
    search_url = (
        f"{base_url}?action=query&list=search&srprop=&srlimit=1&limit=1"
        f"&srsearch={encoded_query}&srinfo=suggestion&format=json"
    )
    try:
        data = _http_get_json(search_url)
    except Exception as e:
        return f"error: failed to search Wikipedia: {e}"

    search_results = (data.get("query") or {}).get("search") or []
    if not search_results:
        suggestion = (
            (data.get("query") or {})
            .get("searchinfo", {})
            .get("suggestion")
        )
        hint = f" Did you mean '{suggestion}'?" if suggestion else ""
        return f"error: no results for '{query}'.{hint}"

    title = search_results[0].get("title", "")
    pageid = search_results[0].get("pageid", "")
    if not title or not pageid:
        return f"error: no results for '{query}'."

    # Step 2: fetch the plain-text intro extract for that article.
    title_for_url = urllib.parse.quote(title.replace(" ", "_"))
    extract_url = (
        f"{base_url}?action=query&prop=extracts&explaintext=&"
        f"titles={title_for_url}&exintro=&format=json"
    )
    try:
        extract_data = _http_get_json(extract_url)
    except Exception as e:
        return f"error: failed to fetch Wikipedia extract: {e}"

    pages = (extract_data.get("query") or {}).get("pages") or {}
    page = pages.get(str(pageid), {})
    extract = (page.get("extract") or "").strip()

    if not extract:
        return f"error: no extract available for '{query}'."

    return extract


@llm.hookimpl
def register_tools(register):
    """Register the search_wikipedia tool with llm."""
    register(search_wikipedia)
