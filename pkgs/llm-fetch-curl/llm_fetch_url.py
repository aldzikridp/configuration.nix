"""LLM plugin providing the `fetch_url` tool.

Ported from the equivalent aichat (https://github.com/sigoden/aichat) bash
tool script `fetch_url_via_curl.sh`.

The original script pipes curl through `pandoc` to convert HTML into
GitHub-Flavored Markdown, dropping divs/spans/raw HTML and inline image
tags. This Python port uses `subprocess` to invoke the same `curl` +
`pandoc` + `sed` pipeline, so the on-disk behaviour is identical.

Install (pip):
    llm install -e /path/to/llm-fetch-url

Use:
    llm -T fetch_url "your question" --td
"""

from __future__ import annotations

import shutil
import subprocess

import llm


__version__ = "0.1.0"


def fetch_url(url: str) -> str:
    """Extract the main content from a URL as GitHub-Flavored Markdown.

    Fetches the URL with `curl`, converts the HTML to Markdown with
    `pandoc` (dropping div/span wrappers and raw HTML), then strips any
    inline image tags (including SVGs) with a regex. Useful for getting
    a clean, model-readable version of a web page.

    Args:
        url: The URL to fetch.
    """
    if not url:
        return "error: url must not be empty"

    # Guard against missing tools up front so we get a friendly message
    # instead of a generic FileNotFoundError mid-pipeline.
    for tool in ("curl", "pandoc", "sed"):
        if shutil.which(tool) is None:
            return (
                f"error: '{tool}' not found on PATH. Install it first "
                f"(`pandoc` and `curl` are required by this tool)."
            )

    # Mirror the original bash invocation:
    #
    #   curl -fsSL "$url" | \
    #     pandoc -f html-native_divs-native_spans -t gfm-raw_html --wrap=none | \
    #     sed -E 's/!\[[^]]*\]\([^)]*\)//g'
    #
    # We use a single shelled-out pipeline instead of chaining three
    # subprocess.run calls because pandoc and sed are streaming filters
    # — letting the shell manage the pipes is faster, simpler, and
    # exactly reproduces the original behaviour.
    pipeline = (
        f"set -o pipefail; "
        f"curl -fsSL {_shell_quote(url)} | "
        f"pandoc -f html-native_divs-native_spans -t gfm-raw_html --wrap=none | "
        f"sed -E 's/!\\[[^]]*\\]\\([^)]*\\)//g'"
    )

    try:
        result = subprocess.run(
            ["bash", "-c", pipeline],
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception as e:  # pragma: no cover - defensive
        return f"error: failed to run fetch_url pipeline: {e}"

    # Mirror the original `set -e` + `set -o pipefail` semantics: any
    # non-zero exit anywhere in the pipe is an error. Surface stderr
    # alongside stdout so the model (and `--td`) can see what failed.
    if result.returncode != 0:
        stderr = (result.stderr or "").strip()
        stdout = (result.stdout or "").strip()
        parts = [f"error: fetch_url pipeline exited with code {result.returncode}"]
        if stdout:
            parts.append(f"stdout:\n{stdout}")
        if stderr:
            parts.append(f"stderr:\n{stderr}")
        if len(parts) == 1:
            parts.append("(no output produced)")
        return "\n".join(parts)

    return result.stdout or ""


def _shell_quote(s: str) -> str:
    """Single-quote a string for safe inclusion in a bash command.

    We can't use shlex.quote because we are constructing a bash -c
    pipeline; we need POSIX-shell-safe single-quoting. This matches
    Python's shlex.quote output for typical inputs but is explicit
    about the escaping rule we care about: wrap in single quotes,
    escape any embedded single quotes as '\\''.
    """
    if s == "":
        return "''"
    if all(c.isalnum() or c in "@%+=:,./-_" for c in s):
        return s
    return "'" + s.replace("'", "'\\''") + "'"


@llm.hookimpl
def register_tools(register):
    """Register the fetch_url tool with llm."""
    register(fetch_url)
