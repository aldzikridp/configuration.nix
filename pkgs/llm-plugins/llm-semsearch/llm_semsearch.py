"""LLM plugin providing the `semantic_search` tool.

Calls semsearch's Python library directly (SemanticSearchService) to perform
semantic search over local documents indexed in PostgreSQL + pgvector.

Search defaults (k, filter, rerank) come from:

    <llm.user_dir()>/semantic-search.yaml

    Linux:  ~/.config/io.datasette.llm/semantic-search.yaml
    macOS:  ~/Library/Application Support/io.datasette.llm/semantic-search.yaml

Example config::

    # Default number of results
    k: 10

    # Default filter (optional, JSON-compatible dict)
    filter:
      doc_type: pdf

    # Enable reranking by default
    rerank: true

    # Path to semsearch .env config (optional, defaults to .env in CWD)
    config: /path/to/.env

Args for the tool function override config defaults per-call.
"""

from __future__ import annotations

import json
import sys

import llm
import yaml

from semsearch.config import get_settings
from semsearch.errors import SemSearchError
from semsearch.service import SemanticSearchService

__version__ = "0.1.0"

CONFIG_FILENAME = "semantic-search.yaml"


def _warn(message: str) -> None:
    """Print a warning to stderr (visible with --td)."""
    print(f"llm-semsearch: {message}", file=sys.stderr)


def _load_config() -> dict:
    """Load search defaults from the YAML config file.

    Returns a dict with optional keys: k, filter, rerank, config.
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
    k: int | None = None,
    filter: str | None = None,
    rerank: bool | None = None,
) -> str:
    """Search local documents indexed by semsearch (semantic search).

    Performs a cosine-similarity search over documents previously ingested
    into PostgreSQL + pgvector via ``semsearch ingest``. Returns the most
    relevant document chunks matching the query.

    Args:
        query: The search query string.
        k: Number of results to return (default: from config, or 5).
        filter: JSON filter string to narrow results, e.g.
            '{"doc_type": "pdf"}' or '{"source": {"$ilike": "docs/%"}}'.
        rerank: Whether to rerank results using the configured reranker.
    """
    if not query:
        return "error: query must not be empty"

    # Load config defaults
    config = _load_config()

    # Merge: CLI args override config, config overrides hardcoded defaults
    effective_k = k if k is not None else config.get("k", 5)
    effective_rerank = rerank if rerank is not None else config.get("rerank", False)
    config_path = config.get("config")

    # Parse filter: CLI string takes precedence, then config dict
    filter_dict = None
    if filter is not None:
        try:
            filter_dict = json.loads(filter)
        except json.JSONDecodeError as e:
            return f"error: invalid filter JSON: {e}"
    elif "filter" in config and config["filter"] is not None:
        filter_dict = config["filter"]

    try:
        settings = get_settings(config_path)
        with SemanticSearchService.from_settings(settings) as svc:
            results = svc.search(
                query,
                k=effective_k,
                filter=filter_dict,
                rerank=effective_rerank,
            )
    except SemSearchError as e:
        return f"error: {e}"
    except Exception as e:
        return f"error: semsearch failed: {e}"

    if not results:
        return "No results found."

    return _format_results(results)


def _format_results(results: list) -> str:
    """Format SearchResult objects as readable text for the LLM.

    Each result is presented as:

        [1] /path/to/file.pdf (score: 0.892)
        <chunk content>

    This is easier for LLMs to consume than raw JSON.
    """
    lines = []
    for i, r in enumerate(results, 1):
        source = r.source or "unknown"
        score = r.score
        content = r.content.strip()

        header = f"[{i}] {source} (score: {score:.3f})"
        lines.append(header)
        lines.append(content)
        lines.append("")

    return "\n".join(lines).strip()


@llm.hookimpl
def register_tools(register):
    """Register the semantic_search tool with llm."""
    register(semantic_search)
