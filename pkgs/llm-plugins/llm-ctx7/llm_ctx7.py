"""LLM plugin providing the `ctx7_search` tool.

Ported from the equivalent aichat (https://github.com/sigoden/aichat) bash
tool script `ctx7_search.sh`.

Install:
    llm install -e /path/to/llm-ctx7

Use:
    llm -T ctx7_search "your question" --td
"""

from __future__ import annotations

import subprocess

import llm


__version__ = "0.1.0"


def ctx7_search(command: str, library_id: str, query: str) -> str:
    """Search documentation using the ctx7 CLI.

    Use this to look up official documentation for a specific library or
    framework. The workflow is two-step:

    1. First call this tool with command="library" to resolve a library
       name (e.g. "react") to its full library-id (e.g. "/facebook/react").
    2. Then call this tool again with command="docs", passing the
       library-id returned from step 1, to fetch the relevant docs for
       the query.

    Args:
        command: The ctx7 subcommand to use. Must be either "library"
            (used first, to resolve a library name to a library-id) or
            "docs" (used second, to fetch the docs for a library-id).
        library_id: The name or library ID, e.g. "react" or
            "/facebook/react".
        query: The search query (max 5000 chars).
    """
    if command not in ("library", "docs"):
        return (
            "error: command must be 'library' or 'docs', got "
            f"{command!r}"
        )
    if not library_id:
        return "error: library_id must not be empty"
    if not query:
        return "error: query must not be empty"
    if len(query) > 5000:
        return (
            "error: query is too long (max 5000 chars, got "
            f"{len(query)})"
        )

    try:
        result = subprocess.run(
            ["ctx7", command, library_id, query],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        return (
            "error: 'ctx7' CLI not found on PATH. Install it first; "
            "see https://ctx7.com for installation instructions."
        )
    except Exception as e:  # pragma: no cover - defensive
        return f"error: failed to invoke ctx7: {e}"

    # Mirror the original bash behaviour: capture both stdout and stderr,
    # and surface stderr alongside stdout when the command fails.
    output = result.stdout or ""
    if result.returncode != 0:
        stderr = result.stderr or ""
        if output and stderr:
            output = output + "\n" + stderr
        else:
            output = output or stderr
        if not output:
            output = (
                f"error: ctx7 {command} exited with code "
                f"{result.returncode} and produced no output"
            )
    return output


@llm.hookimpl
def register_tools(register):
    """Register the ctx7_search tool with llm."""
    register(ctx7_search)
