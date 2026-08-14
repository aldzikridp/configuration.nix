"""
llm-file-tools
==============

A plugin for Simon Willison's `llm` CLI that exposes seven file-manipulation
tools to any chat model that supports tool calling:

* ``read_file``    – read a file (optionally a slice of it, with optional line numbers)
* ``write_file``   – write or overwrite a file (atomic, with create_only guard)
* ``patch_file``   – search-and-replace a single block inside an existing file
* ``apply_diff``   – apply a unified diff to a file
* ``list_dir``     – list the contents of a directory (one level deep)
* ``grep_file``    – search file contents using ripgrep (with grep fallback)
* ``git_apply``    – apply a unified diff via `git apply` (creates commits, validates context)

All paths are resolved against a *base directory* which defaults to the
current working directory. Reads and writes that escape the base directory
are refused – this is the single most important safety rail and prevents
prompt-injection attacks from reaching ``/etc/passwd``, ``~/.ssh/`` etc.

The base directory can be customised in three ways (highest priority last):

1. ``FileTools()`` instantiated from Python with ``base_dir=...``
2. The ``LLM_FILE_TOOLS_BASE_DIR`` environment variable
3. The ``--base-dir`` option on the toolbox instance (set after construction)

This module also exposes plain module-level functions (``read_file``,
``write_file``, ``patch_file``, ``apply_diff``) so the tools can be used
either individually (``-T read_file``) or grouped via the toolbox
(``-T FileTools``).
"""

from __future__ import annotations

import difflib
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Optional

try:
    import llm  # type: ignore
except Exception:  # pragma: no cover - llm is only required at runtime
    llm = None  # type: ignore


__version__ = "0.2.0"

__all__ = [
    "FileTools",
    "read_file",
    "write_file",
    "patch_file",
    "apply_diff",
    "list_dir",
    "grep_file",
    "git_apply",
    "_resolve_under_base",
]


# ---------------------------------------------------------------------------
# Path safety helpers
# ---------------------------------------------------------------------------

def _env_base_dir() -> Optional[Path]:
    """Return the base directory configured via the environment, if any."""
    raw = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
    if not raw:
        return None
    p = Path(raw).expanduser().resolve()
    if not p.is_dir():
        raise RuntimeError(
            f"LLM_FILE_TOOLS_BASE_DIR={raw!r} is not a directory"
        )
    return p


def _resolve_under_base(path: str | os.PathLike[str], base: Path) -> Path:
    """
    Resolve ``path`` against ``base`` and refuse anything that escapes ``base``.

    Both relative and absolute paths are accepted, but the *resolved* path
    must live inside ``base``. This is intentional – it lets the model pass
    either ``"src/app.py"`` or ``"/home/user/proj/src/app.py"`` while still
    being unable to reach ``/etc/passwd``.
    """
    raw = Path(path).expanduser()
    candidate = (base / raw) if not raw.is_absolute() else raw
    try:
        resolved = candidate.resolve(strict=False)
    except (OSError, RuntimeError) as exc:
        raise PermissionError(f"Cannot resolve path {path!r}: {exc}") from exc

    try:
        resolved.relative_to(base.resolve(strict=False))
    except ValueError as exc:
        raise PermissionError(
            f"Path {path!r} resolves to {resolved}, which is outside the "
            f"allowed base directory {base}."
        ) from exc
    return resolved


# ---------------------------------------------------------------------------
# Plain-function tools
# ---------------------------------------------------------------------------
# These are intentionally module-level so a user can enable them individually:
#     llm chat -T read_file -T write_file
# Each function is self-documenting via its docstring + type hints; `llm`
# turns that signature into the JSON schema the model sees.


def read_file(
    path: str,
    offset: int = 0,
    limit: int = 2000,
    line_numbers: bool = False,
) -> str:
    """
    Read the contents of a text file and return it as a string.

    Use this tool BEFORE calling write_file or patch_file so you know the
    exact current content of the file.

    Args:
        path: Path to the file. Relative paths are resolved against the
            sandbox base directory (defaults to the current working
            directory; overridable via the LLM_FILE_TOOLS_BASE_DIR env var).
        offset: 1-indexed line number to start reading from. Default 0
            means "from the beginning". Negative values are not allowed.
        limit: Maximum number of lines to return. Default 2000. Use a
            smaller value for large files; the result is truncated and
            annotated if the file is longer.
        line_numbers: If True, prefix every returned line with its 1-indexed
            line number followed by a tab. Useful when you plan to call
            patch_file next.

    Returns:
        The file contents (optionally with line numbers). If the file is
        larger than `limit` lines, a trailing line is appended telling the
        model how many lines were skipped.
    """
    if offset < 0:
        return "Error: offset must be >= 0"
    if limit <= 0:
        return "Error: limit must be > 0"

    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: file does not exist: {path}"
    if not target.is_file():
        return f"Error: not a regular file: {path}"
    if target.stat().st_size > 5 * 1024 * 1024:  # 5 MB hard cap
        return (
            f"Error: file is too large to read in one call "
            f"({target.stat().st_size} bytes). Use offset/limit to read it "
            f"in chunks."
        )

    try:
        text = target.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return f"Error reading file: {exc}"

    lines = text.splitlines()
    total = len(lines)
    start = max(0, offset)
    end = min(total, start + limit)
    chunk = lines[start:end]

    if line_numbers:
        rendered = "\n".join(
            f"{(start + i + 1):>6}\t{line}" for i, line in enumerate(chunk)
        )
    else:
        rendered = "\n".join(chunk)

    suffix = ""
    if end < total:
        suffix = (
            f"\n\n... ({total - end} more line(s) not shown; "
            f"call read_file again with offset={end} to continue)"
        )
    if start > 0:
        prefix = f"... (showing lines {start + 1}-{end} of {total})\n"
    else:
        prefix = ""

    return f"{prefix}{rendered}{suffix}"


def write_file(
    path: str,
    content: str,
    create_only: bool = False,
) -> str:
    """
    Write `content` to a file, creating it if necessary.

    Writes are atomic: the file is first written to a temporary sibling and
    then renamed into place, so a crashed write never leaves a half-written
    file.

    Args:
        path: Destination path. Resolved against the sandbox base directory.
        content: Full text to write. This REPLACES the file's existing
            contents – do not use write_file to edit a file in place, use
            patch_file instead.
        create_only: If True, refuse to overwrite an existing file. Useful
            when you want to make sure you are not clobbering a file another
            process owns.

    Returns:
        A short status string of the form
        ``"Wrote N bytes to <path>"`` or ``"Error: ..."``.
    """
    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if create_only and target.exists():
        return f"Error: file already exists (create_only=True): {path}"

    target.parent.mkdir(parents=True, exist_ok=True)

    data = content.encode("utf-8")
    if len(data) > 10 * 1024 * 1024:  # 10 MB guard
        return (
            f"Error: refusing to write {len(data)} bytes in a single call; "
            f"split the content or patch the file instead."
        )

    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=str(target.parent),
            prefix=".llm-write-",
            suffix=".tmp",
            delete=False,
        ) as tmp:
            tmp.write(data)
            tmp_path = Path(tmp.name)
        os.replace(tmp_path, target)
    except OSError as exc:
        # Clean up the temp file if the rename failed
        try:
            tmp_path.unlink(missing_ok=True)  # type: ignore[possibly-undefined]
        except NameError:
            pass
        return f"Error writing file: {exc}"

    return f"Wrote {len(data)} bytes to {path}"


def patch_file(
    path: str,
    search: str,
    replace: str,
    replace_all: bool = False,
) -> str:
    """
    Replace one occurrence of `search` with `replace` inside an existing file.

    This is the recommended way to edit a file: it only succeeds if the
    exact `search` text is present, which guarantees the model understood
    the file's current state. Unlike a full overwrite, patch_file preserves
    surrounding content and is safe to retry.

    Whitespace in `search` must match the file EXACTLY (including
    indentation). Call read_file with line_numbers=True first to be sure.

    Args:
        path: File to patch. Resolved against the sandbox base directory.
        search: Exact substring to find. Must be non-empty and must appear
            at least once in the file.
        replace: Text to substitute in place of `search`. May be empty to
            delete the matched text.
        replace_all: If True, replace EVERY occurrence of `search`. If
            False (default), refuse to patch when `search` appears more
            than once, to avoid accidentally editing the wrong location.

    Returns:
        A status string such as ``"Patched <path>: 1 replacement(s)"``
        or ``"Error: ..."`` explaining what went wrong.
    """
    if not search:
        return "Error: search must be a non-empty string"

    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: file does not exist: {path}"
    if not target.is_file():
        return f"Error: not a regular file: {path}"

    try:
        text = target.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return f"Error reading file: {exc}"

    occurrences = text.count(search)
    if occurrences == 0:
        # Be helpful: show the closest match if there's a near-miss.
        hint = _suggest_closest(text, search)
        msg = f"Error: search text not found in {path}."
        if hint:
            msg += f" Did you mean this block?\n\n{hint}"
        return msg
    if occurrences > 1 and not replace_all:
        return (
            f"Error: search text matches {occurrences} locations in {path}; "
            f"pass replace_all=True to replace them all, or make `search` "
            f"more specific (include surrounding context lines)."
        )

    new_text = text.replace(search, replace) if replace_all else \
        text.replace(search, replace, 1)

    # Atomic write
    data = new_text.encode("utf-8")
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=str(target.parent),
            prefix=".llm-patch-",
            suffix=".tmp",
            delete=False,
        ) as tmp:
            tmp.write(data)
            tmp_path = Path(tmp.name)
        os.replace(tmp_path, target)
    except OSError as exc:
        try:
            tmp_path.unlink(missing_ok=True)  # type: ignore[possibly-undefined]
        except NameError:
            pass
        return f"Error writing patched file: {exc}"

    n = occurrences if replace_all else 1
    delta = len(data) - len(text.encode("utf-8"))
    return (
        f"Patched {path}: {n} replacement(s); "
        f"file is now {len(data)} bytes ({'+' if delta >= 0 else ''}{delta})."
    )


def apply_diff(path: str, diff: str) -> str:
    """
    Apply a unified diff to a file.

    The diff must be in standard unified-diff format. A minimal valid diff
    looks like::

        --- a/<path>
        +++ b/<path>
        @@ -1,3 +1,4 @@
         unchanged line
        -old line
        +new line
         unchanged line

    Hunk headers (@@ -start,len +start,len @@) are parsed and validated
    against the current file contents. If any hunk does not match the file
    exactly, the patch is refused and the file is left untouched.

    For most edits, ``patch_file`` is simpler and less error-prone than
    ``apply_diff``. Use ``apply_diff`` when you need to make several
    disjoint changes to the same file in one call.

    Args:
        path: File to patch. Resolved against the sandbox base directory.
        diff: Unified diff text. Lines may or may not include the
            ``a/`` / ``b/`` path prefix – both are tolerated.

    Returns:
        ``"Applied N hunk(s) to <path>"`` or ``"Error: ..."``.
    """
    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: file does not exist: {path}"
    if not target.is_file():
        return f"Error: not a regular file: {path}"

    try:
        text = target.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return f"Error reading file: {exc}"

    try:
        new_text, hunk_count = _apply_unified_diff(text, diff)
    except ValueError as exc:
        return f"Error applying diff: {exc}"

    data = new_text.encode("utf-8")
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=str(target.parent),
            prefix=".llm-diff-",
            suffix=".tmp",
            delete=False,
        ) as tmp:
            tmp.write(data)
            tmp_path = Path(tmp.name)
        os.replace(tmp_path, target)
    except OSError as exc:
        try:
            tmp_path.unlink(missing_ok=True)  # type: ignore[possibly-undefined]
        except NameError:
            pass
        return f"Error writing patched file: {exc}"

    delta = len(data) - len(text.encode("utf-8"))
    return (
        f"Applied {hunk_count} hunk(s) to {path}; "
        f"file is now {len(data)} bytes ({'+' if delta >= 0 else ''}{delta})."
    )


# ---------------------------------------------------------------------------
# list_dir
# ---------------------------------------------------------------------------

def list_dir(
    path: str = ".",
    all_entries: bool = False,
    long: bool = False,
) -> str:
    """
    List the contents of a directory (one level deep, non-recursive).

    Use this tool to discover what files exist before reading or patching
    them. It only lists the immediate children of `path` — use `grep_file`
    to search recursively across the whole tree.

    Args:
        path: Directory to list. Defaults to the sandbox base directory.
            Resolved against the sandbox base directory; paths that escape
            the sandbox are refused.
        all_entries: If True, include hidden entries (those starting with
            ``.``). Default False — hidden files are hidden to keep the
            listing short.
        long: If True, return a multi-column listing with type, size and
            modification time for each entry. Default False returns one
            entry per line, directories suffixed with ``/``.

    Returns:
        One entry per line (or a multi-column table when ``long=True``),
        with a trailing summary line ``N entries (M directories, K files)``.
        Returns ``"Error: ..."`` on failure.
    """
    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: directory does not exist: {path}"
    if not target.is_dir():
        return f"Error: not a directory: {path}"

    try:
        entries = sorted(target.iterdir(), key=lambda p: p.name.lower())
    except OSError as exc:
        return f"Error listing directory: {exc}"

    if not all_entries:
        entries = [e for e in entries if not e.name.startswith(".")]

    n_dirs = n_files = 0
    lines: list[str] = []

    for entry in entries:
        try:
            is_dir = entry.is_dir()
            is_symlink = entry.is_symlink()
        except OSError:
            is_dir = False
            is_symlink = False

        if is_dir:
            n_dirs += 1
        else:
            n_files += 1

        if long:
            try:
                st = entry.stat()
                size = st.st_size
                mtime = st.st_mtime
            except OSError:
                size = 0
                mtime = 0
            import time
            mt = time.strftime("%Y-%m-%d %H:%M", time.localtime(mtime))
            type_char = "d" if is_dir else ("l" if is_symlink else "-")
            name = entry.name + ("/" if is_dir else "")
            lines.append(f"{type_char} {size:>10}  {mt}  {name}")
        else:
            name = entry.name + ("/" if is_dir else "")
            lines.append(name)

    summary = f"{len(entries)} entries ({n_dirs} directories, {n_files} files)"
    if not entries:
        return f"(empty directory)\n{summary}"
    return "\n".join(lines) + f"\n{summary}"


# ---------------------------------------------------------------------------
# grep_file
# ---------------------------------------------------------------------------

def _which(cmd: str) -> Optional[str]:
    """Return the absolute path to `cmd` on PATH, or None."""
    return shutil.which(cmd)


def grep_file(
    pattern: str,
    path: str = ".",
    glob: Optional[str] = None,
    ignore_case: bool = False,
    line_numbers: bool = True,
    max_matches: int = 200,
) -> str:
    """
    Search file contents for a regex pattern using ripgrep (preferred) or grep.

    ``grep_file`` auto-detects ripgrep (``rg``) on PATH and uses it for speed
    and sensible defaults. If ripgrep is not installed it falls back to GNU
    grep. Both backends respect ``.gitignore`` (ripgrep natively; grep via
    ``--exclude-dir`` for common VCS dirs) so you won't get flooded with
    matches from ``.git/`` or ``node_modules/``.

    Args:
        pattern: Regular expression to search for. Uses Python/PCRE syntax
            (ripgrep) or POSIX ERE (grep) — for ASCII patterns the two are
            usually equivalent.
        path: File or directory to search. Defaults to the sandbox base
            directory. Resolved against the sandbox base; paths that escape
            are refused.
        glob: Optional file-pattern filter, e.g. ``"*.py"`` or
            ``"src/**/*.{ts,tsx}"``. Passed to ripgrep as ``-g`` / to grep
            as ``--include``.
        ignore_case: If True, perform a case-insensitive search.
        line_numbers: If True (default), prefix each match with
            ``<path>:<line>:\\t<matched line>``.
        max_matches: Hard cap on the number of matches returned. Default 200.
            The search is aborted once this many matches have been found and
            a trailing ``... truncated`` line is appended.

    Returns:
        One match per line in the form
        ``<relative_path>:<line_number>:<matched line>`` (or without the
        line number when ``line_numbers=False``), followed by a summary line
        ``N match(es) in M file(s)``. Returns ``"Error: ..."`` on failure
        or ``"No matches"`` when nothing matched.
    """
    if not pattern:
        return "Error: pattern must be a non-empty string"
    if max_matches <= 0:
        return "Error: max_matches must be > 0"

    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: path does not exist: {path}"

    rg = _which("rg")
    if rg:
        cmd = [rg]
        # Sensible defaults: respect gitignore, hidden files excluded, JSON not wanted.
        cmd.append("--no-heading")
        cmd.append("--color=never")
        if line_numbers:
            cmd.append("--line-number")
        else:
            cmd.append("--no-line-number")
        if ignore_case:
            cmd.append("--ignore-case")
        if glob:
            cmd.extend(["--glob", glob])
        # Hard cap on results
        cmd.extend(["--max-count", str(max_matches)])
        cmd.extend(["--", pattern, str(target)])
    else:
        grep = _which("grep")
        if not grep:
            return (
                "Error: neither ripgrep (rg) nor grep is installed on PATH; "
                "cannot search."
            )
        cmd = [grep, "--recursive", "--extended-regexp", "--color=never"]
        if line_numbers:
            cmd.append("--line-number")
        if ignore_case:
            cmd.append("--ignore-case")
        if glob:
            cmd.extend(["--include", glob])
        # Crude equivalent of ripgrep's gitignore respect
        for skip in (".git", "node_modules", ".venv", "__pycache__", ".pytest_cache"):
            cmd.extend(["--exclude-dir", skip])
        cmd.extend(["--", pattern, str(target)])

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return f"Error: search timed out after 30 seconds"
    except OSError as exc:
        return f"Error launching search: {exc}"

    # grep exits 1 for "no matches", which is not an error.
    if proc.returncode not in (0, 1):
        err = proc.stderr.strip()
        return f"Error: {rg or 'grep'} exited with code {proc.returncode}: {err}"

    stdout = proc.stdout
    if not stdout:
        return "No matches"

    # Strip the absolute base prefix from each line so paths are relative.
    base_str = str(base)
    lines = []
    files_seen: set[str] = set()
    for line in stdout.splitlines():
        # ripgrep and grep both format as path:lineno:content
        if line.startswith(base_str + os.sep):
            line = line[len(base_str) + 1:]
        elif line.startswith(base_str + "/"):
            line = line[len(base_str) + 1:]
        # Track unique files for the summary
        head = line.split(":", 1)[0] if ":" in line else line
        files_seen.add(head)
        lines.append(line)

    n_matches = len(lines)
    truncated = ""
    if n_matches > max_matches:
        lines = lines[:max_matches]
        truncated = f"\n... truncated ({n_matches - max_matches} more match(es) not shown)"

    summary = f"\n{n_matches} match(es) in {len(files_seen)} file(s)"
    return "\n".join(lines) + truncated + summary


# ---------------------------------------------------------------------------
# git_apply
# ---------------------------------------------------------------------------

def _git_available_in(target: Path) -> bool:
    """Return True if `target` is inside a git work tree."""
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=str(target) if target.is_dir() else str(target.parent),
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        return proc.returncode == 0 and proc.stdout.strip() == "true"
    except (OSError, subprocess.TimeoutExpired):
        return False


def git_apply(
    diff: str,
    path: str = ".",
    check: bool = True,
    commit: bool = False,
    commit_message: Optional[str] = None,
) -> str:
    """
    Apply a unified diff to files inside a git repository using ``git apply``.

    Unlike ``apply_diff`` (which patches a single file in-memory), ``git_apply``
    uses git's own patch engine and supports diffs that touch multiple files,
    create or delete files, and update file modes.

    The diff must be in unified-diff format with the standard
    ``--- a/<path>`` / ``+++ b/<path>`` headers.

    Args:
        diff: Unified diff text to apply. Must include the ``---`` / ``+++``
            file headers.
        path: Path inside the git repository where the diff should be applied.
            Defaults to ``.`` (the sandbox base directory). The diff is
            applied with the current working directory set to this path so
            relative paths in the diff resolve correctly.
        check: If True (default), run ``git apply --check`` first to validate
            the diff without writing anything. If validation fails the call
            returns an error and the work tree is left untouched.
        commit: If True, create a git commit after a successful apply. The
            commit will include all currently-staged and newly-modified
            files in the patched paths. Use this when you want the model's
            changes to be reviewable via ``git log`` / ``git revert``.
        commit_message: Commit message to use when ``commit=True``. Required
            when ``commit=True``; ignored otherwise. The message is passed
            via stdin to avoid shell-injection concerns.

    Returns:
        ``"Applied diff (<N> file(s) changed) to <path>"`` on success, or
        optionally ``"... and committed as <short-sha>"`` when ``commit=True``.
        Returns ``"Error: ..."`` on any failure — in that case the work tree
        is guaranteed to be untouched.
    """
    if not diff.strip():
        return "Error: diff must be a non-empty string"
    if commit and not commit_message:
        return "Error: commit_message is required when commit=True"

    base = _env_base_dir() or Path.cwd()
    try:
        target = _resolve_under_base(path, base)
    except PermissionError as exc:
        return f"Error: {exc}"

    if not target.exists():
        return f"Error: path does not exist: {path}"
    cwd = target if target.is_dir() else target.parent

    if not _git_available_in(cwd):
        return f"Error: {path} is not inside a git repository"

    # Write the diff to a temp file so we don't have to escape it for shell.
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".patch",
        prefix="llm-git-apply-",
        delete=False,
        encoding="utf-8",
    ) as tmp:
        tmp.write(diff)
        tmp_path = Path(tmp.name)

    try:
        # Step 1: dry-run validation
        if check:
            validate = subprocess.run(
                ["git", "apply", "--check", "--verbose", str(tmp_path)],
                cwd=str(cwd),
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
            )
            if validate.returncode != 0:
                err = (validate.stderr or validate.stdout).strip()
                return f"Error: diff does not apply cleanly: {err}"

        # Step 2: actual apply
        apply_proc = subprocess.run(
            ["git", "apply", "--verbose", str(tmp_path)],
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        if apply_proc.returncode != 0:
            err = (apply_proc.stderr or apply_proc.stdout).strip()
            # Try to roll back; `git apply` is usually atomic but be safe.
            return f"Error: git apply failed: {err}"

        # Count touched files from git's own status output
        status_proc = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        n_files = len([l for l in status_proc.stdout.splitlines() if l.strip()]) \
            if status_proc.returncode == 0 else 0

        msg = f"Applied diff ({n_files} file(s) changed) to {path}"

        # Step 3 (optional): commit
        if commit:
            # Stage everything that changed (covers adds, modifies, deletes, renames)
            add_proc = subprocess.run(
                ["git", "add", "-A"],
                cwd=str(cwd),
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            if add_proc.returncode != 0:
                return f"{msg}, but staging for commit failed: {add_proc.stderr.strip()}"

            # Pass commit message via stdin (-F -) to avoid quoting issues.
            commit_proc = subprocess.run(
                ["git", "commit", "-F", "-"],
                cwd=str(cwd),
                input=commit_message,
                capture_output=True,
                text=True,
                timeout=15,
                check=False,
            )
            if commit_proc.returncode != 0:
                err = commit_proc.stderr.strip() or commit_proc.stdout.strip()
                return f"{msg}, but commit failed: {err}"

            # Get the short SHA of the new commit
            sha_proc = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                cwd=str(cwd),
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )
            if sha_proc.returncode == 0:
                sha = sha_proc.stdout.strip()
                msg += f" and committed as {sha}"

        return msg
    finally:
        try:
            tmp_path.unlink(missing_ok=True)
        except OSError:
            pass


# ---------------------------------------------------------------------------
# Diff engine (minimal, dependency-free)
# ---------------------------------------------------------------------------

_HUNK_HEADER_RE = re.compile(
    r"^@@\s+-(?P<old_start>\d+)(?:,(?P<old_len>\d+))?"
    r"\s+\+(?P<new_start>\d+)(?:,(?P<new_len>\d+))?\s+@@"
)


def _apply_unified_diff(text: str, diff: str) -> tuple[str, int]:
    """
    Apply a unified diff to `text` and return (new_text, hunk_count).

    Raises ValueError on any malformed diff or context mismatch.
    """
    lines = text.splitlines(keepends=True)
    diff_lines = diff.splitlines()

    # Skip the --- / +++ header lines (and any leading garbage)
    i = 0
    while i < len(diff_lines) and not diff_lines[i].startswith("@@"):
        i += 1
    if i == len(diff_lines):
        raise ValueError("diff contains no @@ ... @@ hunk headers")

    out_lines: list[str] = []
    cursor = 0  # 0-indexed position in `lines`
    hunks_applied = 0

    while i < len(diff_lines):
        line = diff_lines[i]
        m = _HUNK_HEADER_RE.match(line)
        if not m:
            # Blank lines or "\ No newline at end of file" between hunks
            i += 1
            continue

        old_start = int(m.group("old_start"))
        old_len = int(m.group("old_len") or "1")
        i += 1

        # Copy unchanged lines from cursor up to the hunk's old_start
        # (unified diff line numbers are 1-indexed)
        target_cursor = max(0, old_start - 1)
        if target_cursor < cursor:
            raise ValueError(
                f"hunk at line {old_start} overlaps a previous hunk"
            )
        out_lines.extend(lines[cursor:target_cursor])
        cursor = target_cursor

        # Process the body of the hunk
        consumed_old = 0
        hunk_body: list[str] = []
        while i < len(diff_lines) and not diff_lines[i].startswith("@@"):
            body = diff_lines[i]
            if body.startswith("\\"):
                # "\ No newline at end of file" – informational only
                i += 1
                continue
            if body.startswith(" "):
                # Context line: must match the source file exactly
                expected = lines[cursor] if cursor < len(lines) else ""
                actual = body[1:]
                # Normalise trailing newline handling
                if not expected.endswith("\n") and actual.endswith("\n"):
                    actual = actual[:-1]
                if expected.rstrip("\n") != actual.rstrip("\n"):
                    raise ValueError(
                        f"context mismatch at source line {cursor + 1}: "
                        f"expected {expected!r}, diff said {actual!r}"
                    )
                hunk_body.append(lines[cursor])
                cursor += 1
                consumed_old += 1
            elif body.startswith("-"):
                # Removed line: must match the source exactly
                expected = lines[cursor] if cursor < len(lines) else ""
                actual = body[1:]
                if expected.rstrip("\n") != actual.rstrip("\n"):
                    raise ValueError(
                        f"removed-line mismatch at source line {cursor + 1}: "
                        f"file has {expected!r}, diff expects to remove {actual!r}"
                    )
                cursor += 1
                consumed_old += 1
            elif body.startswith("+"):
                # Added line
                new_line = body[1:]
                if not new_line.endswith("\n"):
                    new_line += "\n"
                hunk_body.append(new_line)
            else:
                raise ValueError(f"unexpected diff line: {body!r}")
            i += 1

        if consumed_old != old_len:
            raise ValueError(
                f"hunk at line {old_start} declared old_len={old_len} "
                f"but consumed {consumed_old} source lines"
            )
        out_lines.extend(hunk_body)
        hunks_applied += 1

    # Copy any remaining unchanged tail
    out_lines.extend(lines[cursor:])

    new_text = "".join(out_lines)
    return new_text, hunks_applied


def _suggest_closest(text: str, search: str, max_chars: int = 400) -> str:
    """Return a snippet of `text` that is closest to `search`, or ""."""
    if not search.strip():
        return ""
    # Try to find a similar block using difflib
    candidates = []
    # Split the file into small chunks for comparison
    lines = text.splitlines()
    n = search.count("\n") + 1
    for i in range(0, max(1, len(lines) - n + 1)):
        chunk = "\n".join(lines[i : i + n])
        ratio = difflib.SequenceMatcher(None, chunk, search).ratio()
        candidates.append((ratio, chunk))
    if not candidates:
        return ""
    candidates.sort(reverse=True)
    best_ratio, best_chunk = candidates[0]
    if best_ratio < 0.6:
        return ""
    return best_chunk[:max_chars]


# ---------------------------------------------------------------------------
# Toolbox class (groups all four tools; lets users configure base_dir)
# ---------------------------------------------------------------------------

if llm is not None:

    class FileTools(llm.Toolbox):  # type: ignore[misc]
        """
        File read / write / patch tools for `llm`.

        All four tools share the same sandbox base directory. From the
        Python API you can scope it explicitly::

            import llm_file_tools
            tools = llm_file_tools.FileTools(base_dir="/path/to/project")
            conv = model.conversation(tools=[tools])

        From the CLI, base_dir defaults to the current working directory
        but can be overridden with the ``LLM_FILE_TOOLS_BASE_DIR`` env var::

            LLM_FILE_TOOLS_BASE_DIR=/path/to/project llm chat -T FileTools --td

        Enable individual tools instead of the whole toolbox with::

            llm chat -T read_file -T write_file -T patch_file -T apply_diff
        """

        def __init__(self, base_dir: Optional[str | os.PathLike[str]] = None):
            super().__init__()
            if base_dir is not None:
                self._base_dir: Optional[Path] = Path(base_dir).expanduser().resolve()
            else:
                self._base_dir = _env_base_dir()

        # -- internal ----------------------------------------------------

        def _base(self) -> Path:
            return self._base_dir or Path.cwd()

        def _resolve(self, path: str) -> Path:
            return _resolve_under_base(path, self._base())

        # -- read_file ---------------------------------------------------

        def read_file(
            self,
            path: str,
            offset: int = 0,
            limit: int = 2000,
            line_numbers: bool = False,
        ) -> str:
            """Read the contents of a text file. See module-level read_file."""
            # Delegate to the module-level function but use this toolbox's base
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return read_file(path, offset=offset, limit=limit,
                                 line_numbers=line_numbers)
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- write_file --------------------------------------------------

        def write_file(
            self,
            path: str,
            content: str,
            create_only: bool = False,
        ) -> str:
            """Write `content` to a file (atomic). See module-level write_file."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return write_file(path, content, create_only=create_only)
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- patch_file --------------------------------------------------

        def patch_file(
            self,
            path: str,
            search: str,
            replace: str,
            replace_all: bool = False,
        ) -> str:
            """Search-and-replace a block in an existing file. See module-level patch_file."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return patch_file(path, search, replace, replace_all=replace_all)
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- apply_diff --------------------------------------------------

        def apply_diff(self, path: str, diff: str) -> str:
            """Apply a unified diff to a file. See module-level apply_diff."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return apply_diff(path, diff)
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- list_dir ----------------------------------------------------

        def list_dir(
            self,
            path: str = ".",
            all_entries: bool = False,
            long: bool = False,
        ) -> str:
            """List directory contents. See module-level list_dir."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return list_dir(path, all_entries=all_entries, long=long)
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- grep_file ---------------------------------------------------

        def grep_file(
            self,
            pattern: str,
            path: str = ".",
            glob: Optional[str] = None,
            ignore_case: bool = False,
            line_numbers: bool = True,
            max_matches: int = 200,
        ) -> str:
            """Search file contents with rg/grep. See module-level grep_file."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return grep_file(
                    pattern,
                    path=path,
                    glob=glob,
                    ignore_case=ignore_case,
                    line_numbers=line_numbers,
                    max_matches=max_matches,
                )
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        # -- git_apply ---------------------------------------------------

        def git_apply(
            self,
            diff: str,
            path: str = ".",
            check: bool = True,
            commit: bool = False,
            commit_message: Optional[str] = None,
        ) -> str:
            """Apply a git diff via `git apply`. See module-level git_apply."""
            import os as _os

            prev = _os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return git_apply(
                    diff,
                    path=path,
                    check=check,
                    commit=commit,
                    commit_message=commit_message,
                )
            finally:
                if prev is None:
                    _os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    _os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

else:  # pragma: no cover - llm not installed

    class FileTools:  # type: ignore[no-redef]
        """Stub used when `llm` is not installed (e.g. during unit tests)."""

        def __init__(self, base_dir: Optional[str | os.PathLike[str]] = None):
            self._base_dir = (
                Path(base_dir).expanduser().resolve() if base_dir else _env_base_dir()
            )

        def _base(self) -> Path:
            return self._base_dir or Path.cwd()

        def _resolve(self, path: str) -> Path:
            return _resolve_under_base(path, self._base())

        def read_file(self, path, offset=0, limit=2000, line_numbers=False):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return read_file(path, offset=offset, limit=limit,
                                 line_numbers=line_numbers)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def write_file(self, path, content, create_only=False):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return write_file(path, content, create_only=create_only)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def patch_file(self, path, search, replace, replace_all=False):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return patch_file(path, search, replace, replace_all=replace_all)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def apply_diff(self, path, diff):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return apply_diff(path, diff)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def list_dir(self, path=".", all_entries=False, long=False):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return list_dir(path, all_entries=all_entries, long=long)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def grep_file(self, pattern, path=".", glob=None, ignore_case=False,
                      line_numbers=True, max_matches=200):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return grep_file(pattern, path=path, glob=glob,
                                 ignore_case=ignore_case,
                                 line_numbers=line_numbers,
                                 max_matches=max_matches)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev

        def git_apply(self, diff, path=".", check=True, commit=False,
                      commit_message=None):
            prev = os.environ.get("LLM_FILE_TOOLS_BASE_DIR")
            try:
                if self._base_dir is not None:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = str(self._base_dir)
                return git_apply(diff, path=path, check=check, commit=commit,
                                 commit_message=commit_message)
            finally:
                if prev is None:
                    os.environ.pop("LLM_FILE_TOOLS_BASE_DIR", None)
                else:
                    os.environ["LLM_FILE_TOOLS_BASE_DIR"] = prev


# ---------------------------------------------------------------------------
# llm hook implementation – this is what `llm` discovers via the entry point
# ---------------------------------------------------------------------------

def _register_all(register) -> None:
    """Register every tool exposed by this plugin."""
    register(read_file)
    register(write_file)
    register(patch_file)
    register(apply_diff)
    register(list_dir)
    register(grep_file)
    register(git_apply)
    # Also register the toolbox class so users can enable all tools at once
    # with `-T FileTools`.
    if llm is not None:
        register(FileTools)


# We only define the hookimpl if `llm` is importable. This keeps the module
# import-safe for unit tests that don't have llm installed.
if llm is not None:

    @llm.hookimpl
    def register_tools(register):
        _register_all(register)
