"""LLM plugin providing the `semantic_search` tool via HTTP API.

Sends search requests to a running `semsearch serve` endpoint instead of
calling the Python library directly. This allows the LLM to query a remote
or shared semantic search server.

Search defaults (host, port, k, rerank) come from:

    <llm.user_dir()>/semantic-search-server.yaml

    Linux:  ~/.config/io.datasette.llm/semantic-search-server.yaml
    macOS:  ~/Library/Application Support/io.datasette.llm/semantic-search-server.yaml

Example config::

    # Server host
    host: localhost

    # Server port
    port: 8383

    # Default number of results
    k: 10

    # Enable reranking by default
    rerank: true

Args for the tool function override config defaults per-call.
"""

from __future__ import annotations

import json
import sys

import httpx2 as httpx
import llm
import yaml

__version__ = "0.1.0"

CONFIG_FILENAME = "semantic-search-server.yaml"

# Defaults
DEFAULT_HOST = "localhost"
DEFAULT_PORT = 8383
DEFAULT_K = 5
DEFAULT_RERANK = False
REQUEST_TIMEOUT = 30.0


def _warn(message: str) -> None:
    """Print a warning to stderr (visible with --td)."""
    print(f"llm-semantic-search: {message}", file=sys.stderr)


def _load_config() -> dict:
    """Load search defaults from the YAML config file.

    Returns a dict with optional keys: host, port, k, rerank.
    Never raises: missing/broken config returns empty dict with a warning.
    """
    path = llm.user_dir() / CONFIG_FILENAME
    if not path.exists():
        return {}

    try:
        data = yaml.safe_load(path.read_text())
    except Exception as e:
        _warn(f"failed to parse {path}: {e}")
        return {}

    if not isinstance(data, dict):
        _warn(f"config file must be a YAML mapping, got {type(data).__name__}")
        return {}

    return data


def semantic_search(
    query: str,
    filter: str | None = None,
) -> str:
    """Semantic search

    Args:
        query: The search query string.
        filter: JSON filter string to narrow results
            - Specific file → `{"source": "path/to/file.md"}`
            - File type → `{"doc_type": "pdf"}`
            - Directory → `{"source": {"$ilike": "docs/%"}}`
            - Multiple types → `{"doc_type": {"$in": ["pdf", "csv"]}}`
            - Exclude type → `{"doc_type": {"$ne": "json"}}`
            - Page range → `{"page": {"$between": [1, 10]}}`
            - Combine AND → `{"$and": [{...}, {...}]}`
            - Combine OR → `{"$or": [{...}, {...}]}`
            - Negate → `{"$not": {...}}`
            - Field exists → `{"page": {"$exists": true}}`
    """
    if not query:
        return "error: query must not be empty"

    # Load config defaults
    config = _load_config()

    # Merge: CLI args override config, config overrides hardcoded defaults
    effective_host = config.get("host", DEFAULT_HOST)
    effective_port = config.get("port", DEFAULT_PORT)
    effective_k = config.get("k", DEFAULT_K)
    effective_rerank = config.get("rerank", DEFAULT_RERANK)

    # Parse filter: CLI string takes precedence, then config dict
    filter_dict = None
    if filter is not None:
        try:
            filter_dict = json.loads(filter)
        except json.JSONDecodeError as e:
            return f"error: invalid filter JSON: {e}"
    elif "filter" in config and config["filter"] is not None:
        filter_dict = config["filter"]

    # Build request payload
    payload = {
        "query": query,
        "k": effective_k,
        "rerank": effective_rerank,
    }
    if filter_dict is not None:
        payload["filter"] = filter_dict

    # Make HTTP request
    base_url = f"http://{effective_host}:{effective_port}"
    try:
        client = httpx.Client(base_url=base_url, timeout=REQUEST_TIMEOUT)
        response = client.post("/search", json=payload)
        response.raise_for_status()
    except httpx.ConnectError:
        return f"error: cannot connect to semsearch server at {base_url}. Is `semsearch serve` running?"
    except httpx.TimeoutException:
        return f"error: request to semsearch server timed out after {REQUEST_TIMEOUT}s"
    except httpx.HTTPStatusError as e:
        return f"error: semsearch server returned {e.response.status_code}: {e.response.text}"
    except Exception as e:
        return f"error: request failed: {e}"

    # Parse response
    try:
        data = response.json()
    except Exception as e:
        return f"error: invalid response from server: {e}"

    results = data.get("results", [])
    if not results:
        return "No results found."

    return _format_results(results)


def _format_results(results: list[dict]) -> str:
    """Format search results as readable text for the LLM.

    Each result is presented as:

        [1] /path/to/file.pdf (score: 0.892)
        <chunk content>

    This is easier for LLMs to consume than raw JSON.
    """
    lines = []
    for i, r in enumerate(results, 1):
        source = r.get("source", "unknown")
        score = r.get("score", 0.0)
        content = r.get("content", "").strip()

        header = f"[{i}] {source} (score: {score:.3f})"
        lines.append(header)
        lines.append(content)
        lines.append("")

    return "\n".join(lines).strip()


@llm.hookimpl
def register_tools(register):
    """Register the semantic_search tool with llm."""
    register(semantic_search)
