"""llm plugin: Command Code (commandcode.ai) model provider.

Registers models from the Command Code Provider API
(https://api.commandcode.ai/provider/v1/models) as ``commandcode/{id}``
(e.g. ``commandcode/deepseek/deepseek-v4-flash``) and streams completions
from ``POST /alpha/generate``.

Feature scope (full parity with the pi extension's provider runtime):

- streaming text
- tool calling (llm tools <-> CC ``tool-call``/``tool-result`` messages)
- reasoning / thinking (CC ``reasoning-delta`` -> llm reasoning events;
  prior reasoning is never replayed in follow-up requests)
- image input for vision-capable models (data-URL wire format)
- dynamic model catalog with a local cache
- ``-o reasoning_effort`` mapped through the per-model effort catalog
- ``llm commandcode-models`` diagnostic / refresh command

Not ported (pi-only, no llm equivalent): the browser OAuth ``/login`` flow
(use ``llm keys set commandcode`` instead), pi's per-request cost display,
and pi's context-overflow error normalization.

Auth: ``llm keys set commandcode`` or the ``COMMANDCODE_API_KEY``
environment variable, plus a fallback that reads existing credentials from
``~/.commandcode/auth.json``, ``~/.pi/agent/auth.json`` and
``~/.omp/agent/auth.json`` (handy for existing pi users).
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import uuid
from datetime import date
from pathlib import Path
from typing import Any, Iterator, Optional, Union

import click
import httpx

import llm
from llm.parts import StreamEvent

__version__ = "0.1.0"

# ──────────────────────────────────────────────────────────────────────────
# Constants (copied verbatim from the pi extension's TypeScript source).
# ──────────────────────────────────────────────────────────────────────────

COMMAND_CODE_CLI_VERSION = "1.15.1"
DEFAULT_API_BASE = "https://api.commandcode.ai"
DEFAULT_MODELS_URL = "https://api.commandcode.ai/provider/v1/models"
DEFAULT_MODELS_TIMEOUT_MS = 10_000
DEFAULT_MODELS_TTL_SECONDS = 24 * 60 * 60  # cache first, refresh after 24h
DEFAULT_GENERATE_MAX_TOKENS = 64_000
DEFAULT_MAX_OUTPUT_TOKENS = 65_536
MODEL_CACHE_VERSION = 1

# MIME types accepted for image attachments (CC sends images as data URLs).
IMAGE_ATTACHMENT_TYPES = frozenset(
    {
        "image/png",
        "image/jpeg",
        "image/jpg",
        "image/gif",
        "image/webp",
    }
)

# Model input modalities from the command-code@1.15.1 bundled catalog.
# Models omitted here remain text-only so newly discovered IDs never claim
# image support without upstream evidence.
MODEL_INPUT_MODALITIES: dict[str, tuple[str, ...]] = {
    "MiniMaxAI/MiniMax-M3": ("text", "image"),
    "Qwen/Qwen3.6-Plus": ("text", "image"),
    "Qwen/Qwen3.7-Flash": ("text", "image"),
    "Qwen/Qwen3.7-Plus": ("text", "image"),
    "Qwen/Qwen3.8-Max": ("text", "image"),
    "claude-fable-5": ("text", "image"),
    "claude-haiku-4-5-20251001": ("text", "image"),
    "claude-opus-4-7": ("text", "image"),
    "claude-opus-4-8": ("text", "image"),
    "claude-opus-5": ("text", "image"),
    "claude-sonnet-4-6": ("text", "image"),
    "claude-sonnet-5": ("text", "image"),
    "google/gemini-3.1-flash-lite": ("text", "image"),
    "google/gemini-3.5-flash": ("text", "image"),
    "google/gemini-3.5-flash-lite": ("text", "image"),
    "google/gemini-3.6-flash": ("text", "image"),
    "gpt-5.3-codex": ("text", "image"),
    "gpt-5.4": ("text", "image"),
    "gpt-5.4-mini": ("text", "image"),
    "gpt-5.5": ("text", "image"),
    "gpt-5.6-luna": ("text", "image"),
    "gpt-5.6-sol": ("text", "image"),
    "gpt-5.6-terra": ("text", "image"),
    "meta/muse-spark-1.1": ("text", "image"),
    "meta/muse-spark-1.2": ("text", "image"),
    "meta/muse-spark-1.2-contributor": ("text", "image"),
    "moonshotai/Kimi-K2.5": ("text", "image"),
    "moonshotai/Kimi-K2.6": ("text", "image"),
    "moonshotai/Kimi-K2.7-Code": ("text", "image"),
    "moonshotai/Kimi-K2.7-Code-Highspeed": ("text", "image"),
    "moonshotai/Kimi-K3": ("text", "image"),
    "sakana/fugu-ultra": ("text", "image"),
    "stepfun/Step-3.7-Flash": ("text", "image"),
    "thinkingmachines/inkling": ("text", "image"),
    "thinkingmachines/inkling-small": ("text", "image"),
    "xai/grok-4.5": ("text", "image"),
    "xiaomi/mimo-v2.5": ("text", "image"),
}

# Per-model reasoning efforts supported by Command Code's generate endpoint.
# The Provider API does not expose reasoning metadata; this is an exact
# snapshot of `reasoningEfforts` from the command-code@1.15.1 model catalog.
# Models omitted here let Command Code choose their reasoning depth.
MODEL_EFFORTS: dict[str, tuple[str, ...]] = {
    "Qwen/Qwen3.8-Max": ("low", "medium", "xhigh"),
    "claude-fable-5": ("low", "medium", "high", "xhigh", "max"),
    "claude-opus-4-7": ("low", "medium", "high", "xhigh", "max"),
    "claude-opus-4-8": ("low", "medium", "high", "xhigh", "max"),
    "claude-opus-5": ("low", "medium", "high", "xhigh", "max"),
    "claude-sonnet-4-6": ("low", "medium", "high", "xhigh", "max"),
    "claude-sonnet-5": ("low", "medium", "high", "xhigh", "max"),
    "deepseek/deepseek-v4-flash": ("high", "max"),
    "deepseek/deepseek-v4-pro": ("high", "max"),
    "gpt-5.3-codex": ("low", "medium", "high", "xhigh"),
    "gpt-5.4": ("low", "medium", "high", "xhigh"),
    "gpt-5.4-mini": ("low", "medium", "high"),
    "gpt-5.5": ("low", "medium", "high", "xhigh"),
    "gpt-5.6-luna": ("low", "medium", "high", "xhigh", "max"),
    "gpt-5.6-sol": ("low", "medium", "high", "xhigh", "max"),
    "gpt-5.6-terra": ("low", "medium", "high", "xhigh", "max"),
    "google/gemini-3.1-flash-lite": ("low", "medium", "high"),
    "google/gemini-3.5-flash": ("low", "medium", "high"),
    "google/gemini-3.5-flash-lite": ("low", "medium", "high"),
    "google/gemini-3.6-flash": ("low", "medium", "high"),
    "sakana/fugu-ultra": ("high", "xhigh"),
    "xai/grok-4.5": ("low", "medium", "high"),
    "zai-org/GLM-5.2": ("high", "max"),
}


# ──────────────────────────────────────────────────────────────────────────
# Secrets redaction (simplified port of the TS `redactCommandCodeErrorText`).
# ──────────────────────────────────────────────────────────────────────────

_BEARER_RE = re.compile(r"\bBearer\s+[A-Za-z0-9._~+/=-]+", re.I)
_CREDENTIAL_RE = re.compile(
    r"\b(?:api[-_ ]?key|apikey|access[-_ ]?token|refresh[-_ ]?token|"
    r"token|secret|password|authorization)\s*[=:]\s*[^\s,;)]+",
    re.I,
)
_USER_TOKEN_RE = re.compile(r"\b(?:user|cc)_[A-Za-z0-9_-]{8,}\b")
_QUERY_SECRET_RE = re.compile(
    r"([?&](?:api[-_ ]?key|apikey|access_token|refresh_token|token|secret|password)=)"
    r"[^&#\s]+",
    re.I,
)
_STANDALONE_SECRET_RE = re.compile(
    r"\b(?:sk|rk|ghp|github_pat|xox[baprs])[-_A-Za-z0-9]{16,}\b"
    r"|\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"
)


def redact_secrets(value: str) -> str:
    def credential(match: re.Match) -> str:
        text = match.group(0)
        for sep in ("=", ":"):
            index = text.find(sep)
            if index >= 0:
                return text[: index + 1] + "[redacted]"
        return "[redacted]"

    result = _BEARER_RE.sub("Bearer [redacted]", value)
    result = _CREDENTIAL_RE.sub(credential, result)
    result = _QUERY_SECRET_RE.sub(lambda m: m.group(1) + "[redacted]", result)
    result = _STANDALONE_SECRET_RE.sub("[redacted]", result)
    return result


def _redact_endpoint(value: str) -> str:
    try:
        parts = value.split("://", 1)
        host_path = parts[1] if len(parts) == 2 else parts[0]
        return f"{parts[0]}://{host_path.split('?')[0]}" if len(parts) == 2 else host_path.split("?")[0]
    except Exception:
        return "[redacted]"


# ──────────────────────────────────────────────────────────────────────────
# Small helpers.
# ──────────────────────────────────────────────────────────────────────────

def is_record(value: Any) -> bool:
    return isinstance(value, dict)


def number_value(value: Any) -> Optional[int]:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)) and value == value:  # not NaN
        return int(value)
    return None


def project_slug_from_path(path_name: str) -> str:
    """Port of the TS `projectSlugFromPath`. Also strips Windows drives."""
    slug = re.sub(r"^[a-z]:", "", path_name.lower())
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = re.sub(r"^-+|-+$", "", slug)
    return slug or "project"


def parse_stream_line(line: str) -> Optional[dict]:
    trimmed = line.strip()
    if not trimmed or trimmed.startswith(":") or trimmed.startswith("event:"):
        return None
    if trimmed.startswith("data:"):
        trimmed = trimmed[5:].lstrip()
    if not trimmed or trimmed == "[DONE]":
        return None
    try:
        parsed = json.loads(trimmed)
    except json.JSONDecodeError:
        return None
    return parsed if isinstance(parsed, dict) else None


def cc_error_message(value: Any) -> Optional[str]:
    """Extract a human-readable message from a Command Code error payload."""
    if isinstance(value, str):
        return value
    if not is_record(value):
        return None
    parts: list[str] = []
    for key in ("message", "errorMessage", "error", "detail", "details", "code", "type", "reason"):
        part = cc_error_message(value.get(key))
        if part and part not in parts:
            parts.append(part)
    for key in ("status", "statusCode", "httpStatus"):
        status = value.get(key)
        if isinstance(status, (str, int)):
            status_part = f"status: {status}"
            if status_part not in parts:
                parts.append(status_part)
    return redact_secrets(": ".join(parts)) if parts else None


def _parse_tool_input(raw: Any) -> dict:
    if is_record(raw):
        return dict(raw)
    if isinstance(raw, str):
        try:
            parsed = json.loads(raw)
            if is_record(parsed):
                return parsed
        except json.JSONDecodeError:
            pass
    return {}


# ──────────────────────────────────────────────────────────────────────────
# API key resolution.
# ──────────────────────────────────────────────────────────────────────────

def _credential_record_key(record: dict) -> Optional[str]:
    rtype = record.get("type")
    if rtype == "api":
        value = record.get("key")
    elif rtype == "oauth":
        value = record.get("access")
    else:
        value = record.get("key") or record.get("access")
    return value if isinstance(value, str) and value else None


def _api_key_from_auth_files() -> Optional[str]:
    home = os.path.expanduser("~")
    paths = [
        Path(home) / ".commandcode" / "auth.json",
        Path(home) / ".omp" / "agent" / "auth.json",
        Path(home) / ".pi" / "agent" / "auth.json",
    ]
    override = os.environ.get("COMMANDCODE_AUTH_FILES")
    if override:
        paths = [Path(p) for p in override.split(os.pathsep) if p]

    for path in paths:
        try:
            parsed: Any = json.loads(path.read_text())
        except Exception:
            continue
        if not is_record(parsed):
            continue
        api_key = parsed.get("apiKey")
        if isinstance(api_key, str) and api_key:
            return api_key
        commandcode = parsed.get("commandcode")
        if isinstance(commandcode, str) and commandcode:
            return commandcode
        for key_name in ("commandcode", "command-code"):
            record = parsed.get(key_name)
            if is_record(record):
                value = _credential_record_key(record)
                if value:
                    return value
    return None


# ──────────────────────────────────────────────────────────────────────────
# Model catalog: cache-first loading (llm is a one-shot CLI, so a fresh
# network fetch on every invocation would be unacceptable).
# ──────────────────────────────────────────────────────────────────────────

def _models_cache_path() -> Path:
    override = os.environ.get("COMMANDCODE_MODELS_CACHE")
    if override:
        return Path(override)
    return llm.user_dir() / "commandcode-models.json"


def _models_url() -> str:
    return os.environ.get("COMMANDCODE_MODELS_URL") or DEFAULT_MODELS_URL


def _api_base() -> str:
    return os.environ.get("COMMANDCODE_API_BASE") or DEFAULT_API_BASE


def _models_timeout_ms() -> float:
    raw = os.environ.get("COMMANDCODE_MODELS_TIMEOUT_MS")
    try:
        parsed = float(raw)
        if parsed > 0:
            return parsed
    except (TypeError, ValueError):
        pass
    return DEFAULT_MODELS_TIMEOUT_MS


def _parse_models_response(value: Any) -> list[dict]:
    if not is_record(value) or value.get("object") != "list":
        raise ValueError("Expected models response object to be 'list'")
    data = value.get("data")
    if not isinstance(data, list) or not data:
        raise ValueError("Expected models response data to be a non-empty array")

    models: list[dict] = []
    for entry in data:
        if not is_record(entry):
            raise ValueError("Expected model entry to be an object")
        mid = entry.get("id")
        name = entry.get("name")
        context_length = entry.get("context_length")
        if not isinstance(mid, str) or not mid:
            raise ValueError("Expected id to be a non-empty string")
        if not isinstance(name, str) or not name:
            raise ValueError("Expected name to be a non-empty string")
        if not isinstance(context_length, (int, float)) or isinstance(context_length, bool) or context_length <= 0:
            raise ValueError("Expected context_length to be a positive number")
        context_length = int(context_length)
        models.append(
            _normalize_catalog_entry(
                {
                    "id": mid,
                    "name": name,
                    "contextWindow": context_length,
                    "maxTokens": min(context_length, DEFAULT_MAX_OUTPUT_TOKENS),
                    "reasoning": mid in MODEL_EFFORTS,
                    "image": "image" in MODEL_INPUT_MODALITIES.get(mid, ()),
                }
            )
        )
    return models


def _normalize_catalog_entry(entry: dict) -> dict:
    """Validate a cache/model entry and recompute derived flags."""
    return {
        "id": entry["id"],
        "name": entry["name"],
        "contextWindow": int(entry["contextWindow"]),
        "maxTokens": int(entry["maxTokens"]),
        "reasoning": entry["id"] in MODEL_EFFORTS,
        "image": "image" in MODEL_INPUT_MODALITIES.get(entry["id"], ()),
    }


def _read_cache(path: Path) -> list[dict]:
    parsed: Any = json.loads(path.read_text())
    if not is_record(parsed) or parsed.get("version") != MODEL_CACHE_VERSION:
        raise ValueError(f"Expected model cache version {MODEL_CACHE_VERSION}")
    models = parsed.get("models")
    if not isinstance(models, list) or not models:
        raise ValueError("Expected cached models to be a non-empty array")

    out: list[dict] = []
    for entry in models:
        if not is_record(entry):
            raise ValueError("Expected cached model entry to be an object")
        mid = entry.get("id")
        name = entry.get("name")
        context_window = entry.get("contextWindow")
        max_tokens = entry.get("maxTokens")
        if not isinstance(mid, str) or not mid:
            raise ValueError("Expected id to be a non-empty string")
        if not isinstance(name, str) or not name:
            raise ValueError("Expected name to be a non-empty string")
        if not isinstance(context_window, (int, float)) or isinstance(context_window, bool) or context_window <= 0:
            raise ValueError("Expected contextWindow to be a positive number")
        if not isinstance(max_tokens, (int, float)) or isinstance(max_tokens, bool) or max_tokens <= 0:
            raise ValueError("Expected maxTokens to be a positive number")
        out.append(
            _normalize_catalog_entry(
                {
                    "id": mid,
                    "name": name,
                    "contextWindow": int(context_window),
                    "maxTokens": int(max_tokens),
                    "reasoning": False,
                    "image": False,
                }
            )
        )
    return out


def _write_cache(path: Path, models: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = path.with_name(path.name + ".tmp")
    temporary_path.write_text(
        json.dumps({"version": MODEL_CACHE_VERSION, "models": models}, indent=2)
    )
    temporary_path.replace(path)


def _cache_is_fresh(path: Path, ttl: float = DEFAULT_MODELS_TTL_SECONDS) -> bool:
    try:
        return time.time() - path.stat().st_mtime < ttl
    except OSError:
        return False


def _fetch_models() -> list[dict]:
    url = _models_url()
    timeout = _models_timeout_ms() / 1000.0
    with httpx.Client(timeout=timeout) as client:
        response = client.get(url, headers={"accept": "application/json"})
        response.raise_for_status()
        return _parse_models_response(response.json())


def load_commandcode_models(refresh: bool = False) -> tuple[list[dict], str, Optional[str]]:
    """Return (models, source, warning).

    Cache-first with a 24h TTL; live fetch on miss/expiry/refresh; fall back
    to the (possibly stale) cache when the live fetch fails; otherwise empty.
    """
    cache_path = _models_cache_path()

    if not refresh:
        try:
            if cache_path.exists() and _cache_is_fresh(cache_path):
                return _read_cache(cache_path), "cache", None
        except Exception:
            pass

    try:
        models = _fetch_models()
        try:
            _write_cache(cache_path, models)
        except Exception:
            pass
        return models, "live", None
    except Exception as live_error:  # noqa: BLE001 - surface to user as warning
        try:
            models = _read_cache(cache_path)
            return (
                models,
                "cache",
                f"Could not refresh the Command Code model catalog ({live_error}); "
                f"using the cached catalog from {cache_path}.",
            )
        except Exception as cache_error:  # noqa: BLE001
            return (
                [],
                "empty",
                f"Could not refresh the Command Code model catalog ({live_error}), "
                f"and no valid cached catalog is available at {cache_path} "
                f"({cache_error}). Command Code models are unavailable until a "
                f"refresh succeeds.",
            )


# ──────────────────────────────────────────────────────────────────────────
# Message conversion (llm Message parts -> Command Code wire format).
# Mirrors the TS `messagesToCC` behaviour.
# ──────────────────────────────────────────────────────────────────────────

def _paired_tool_call_ids(messages) -> set[str]:
    call_ids = set()
    result_ids = set()
    for message in messages:
        if message.role == "assistant":
            for part in message.parts:
                if isinstance(part, llm.parts.ToolCallPart) and part.tool_call_id:
                    call_ids.add(part.tool_call_id)
        elif message.role == "tool":
            for part in message.parts:
                if isinstance(part, llm.parts.ToolResultPart) and part.tool_call_id:
                    result_ids.add(part.tool_call_id)
    return call_ids & result_ids


def _image_to_cc(attachment: llm.Attachment) -> dict:
    mime_type = attachment.resolve_type()
    if not mime_type or not mime_type.startswith("image/"):
        raise llm.ModelError(
            f"Invalid image content: expected an image/* attachment, got {mime_type!r}"
        )
    data = attachment.base64_content()
    return {
        "type": "image",
        "image": f"data:{mime_type};base64,{data}",
        "mimeType": mime_type,
    }


def _system_text(prompt) -> str:
    """System prompt: prefer the explicit property, else gather from any
    system-role Message in the chain (preserves the system prompt across
    conversation follow-up turns, since Command Code has no system role)."""
    explicit = prompt.system
    if explicit:
        return explicit
    bits = []
    for message in prompt.messages:
        if message.role == "system":
            for part in message.parts:
                if isinstance(part, llm.parts.TextPart):
                    bits.append(part.text)
    return "\n\n".join(bits)


def messages_to_cc(prompt, model) -> list[dict]:
    from llm.parts import (
        AttachmentPart,
        ReasoningPart,
        TextPart,
        ToolCallPart,
        ToolResultPart,
    )

    paired_ids = _paired_tool_call_ids(prompt.messages)
    out: list[dict] = []

    for message in prompt.messages:
        if message.role == "system":
            # Handled via params.system (CC has no system message role).
            continue
        if message.role == "user":
            content: list[dict] = []
            for part in message.parts:
                if isinstance(part, TextPart):
                    content.append({"type": "text", "text": part.text})
                elif isinstance(part, AttachmentPart) and part.attachment:
                    if not model.supports_images:
                        raise llm.ModelError(
                            "Selected Command Code model does not support image content "
                            "in user messages"
                        )
                    content.append(_image_to_cc(part.attachment))
            if content:
                out.append({"role": "user", "content": content})
        elif message.role == "assistant":
            content = []
            for part in message.parts:
                if isinstance(part, TextPart):
                    content.append({"type": "text", "text": part.text})
                elif isinstance(part, ToolCallPart):
                    # Drop orphaned tool calls (no matching tool result),
                    # matching the pi extension.
                    if part.tool_call_id not in paired_ids:
                        continue
                    content.append(
                        {
                            "type": "tool-call",
                            "toolCallId": part.tool_call_id or "",
                            "toolName": part.name,
                            "input": part.arguments or {},
                        }
                    )
                # ReasoningPart is intentionally dropped: prior private
                # reasoning is never replayed to Command Code.
            if content:
                out.append({"role": "assistant", "content": content})
        elif message.role == "tool":
            tool_results: list[dict] = []
            images: list[llm.Attachment] = []
            for part in message.parts:
                if isinstance(part, ToolResultPart):
                    output_type = "error-text" if part.exception else "text"
                    out.append(
                        {
                            "role": "tool",
                            "content": [
                                {
                                    "type": "tool-result",
                                    "toolCallId": part.tool_call_id or "",
                                    "toolName": part.name,
                                    "output": {
                                        "type": output_type,
                                        "value": part.output or "",
                                    },
                                }
                            ],
                        }
                    )
                    images.extend(a for a in (part.attachments or []) if a)
                elif isinstance(part, AttachmentPart) and part.attachment:
                    images.append(part.attachment)
            if images:
                if not model.supports_images:
                    raise llm.ModelError(
                        "Selected Command Code model does not support image content "
                        "in tool results"
                    )
                out.append(
                    {"role": "user", "content": [_image_to_cc(a) for a in images]}
                )

    return out


def tools_to_cc(tools) -> list[dict]:
    out: list[dict] = []
    for tool in tools:
        if isinstance(tool, llm.ServerSideTool):
            # Command Code has no server-side tool support.
            continue
        out.append(
            {
                "type": "function",
                "name": tool.name,
                "description": tool.description,
                "input_schema": tool.input_schema or {},
            }
        )
    return out


# ──────────────────────────────────────────────────────────────────────────
# Usage.
# ──────────────────────────────────────────────────────────────────────────

def _set_usage(response, finish_event: dict) -> None:
    total = finish_event.get("totalUsage")
    if not is_record(total):
        return
    input_tokens = number_value(total.get("inputTokens"))
    output_tokens = number_value(total.get("outputTokens"))
    details_record = total.get("inputTokenDetails")
    details_record = details_record if is_record(details_record) else {}

    no_cache = number_value(details_record.get("noCacheTokens"))
    cache_read = number_value(details_record.get("cacheReadTokens")) or 0
    cache_write = number_value(details_record.get("cacheWriteTokens")) or 0

    if no_cache is None:
        input_used = max(0, (input_tokens or 0) - cache_read - cache_write)
    else:
        input_used = no_cache

    details: dict[str, Any] = {}
    if cache_read or cache_write:
        details["cache_read_tokens"] = cache_read
        details["cache_write_tokens"] = cache_write

    if details:
        response.set_usage(input=input_used, output=output_tokens, details=details)
    else:
        response.set_usage(input=input_used, output=output_tokens)


# ──────────────────────────────────────────────────────────────────────────
# The model.
# ──────────────────────────────────────────────────────────────────────────

class CommandCodeModel(llm.KeyModel):
    needs_key = "commandcode"
    key_env_var = "COMMANDCODE_API_KEY"

    class Options(llm.Options):
        reasoning_effort: Optional[str] = None
        max_tokens: Optional[int] = None

    def __init__(self, catalog_entry: dict):
        cc_id = catalog_entry["id"]
        self.model_id = f"commandcode/{cc_id}"
        self.cc_model_id = cc_id
        self.context_window = catalog_entry["contextWindow"]
        self.max_tokens = catalog_entry["maxTokens"]
        self.reasoning = catalog_entry["reasoning"]
        self.supports_images = bool(catalog_entry.get("image"))
        self.efforts = MODEL_EFFORTS.get(cc_id, ())
        self.can_stream = True
        self.supports_tools = True
        self.attachment_types = (
            set(IMAGE_ATTACHMENT_TYPES) if self.supports_images else set()
        )

    def __str__(self) -> str:
        return f"CommandCode: {self.model_id}"

    def get_key(self, explicit_key: str | None = None) -> str | None:
        try:
            return super().get_key(explicit_key)
        except llm.NeedsKeyException:
            key = _api_key_from_auth_files()
            if key:
                return key
            raise

    def _resolve_effort(self, requested: Optional[str]) -> Optional[str]:
        if not requested or requested == "off":
            return None
        return requested if requested in self.efforts else None

    def execute(
        self,
        prompt: llm.Prompt,
        stream: bool,
        response: llm.Response,
        conversation: llm.Conversation | None,
        key: str | None,
    ) -> Iterator[Union[str, StreamEvent]]:
        if not key:
            raise llm.NeedsKeyException(
                "No key found - add one using 'llm keys set commandcode' "
                "or set the COMMANDCODE_API_KEY environment variable"
            )

        messages = messages_to_cc(prompt, self)
        tools = tools_to_cc(prompt.tools)
        system_text = _system_text(prompt)

        requested_max = prompt.options.max_tokens or self.max_tokens
        max_tokens = min(int(requested_max), self.max_tokens, DEFAULT_GENERATE_MAX_TOKENS)
        effort = self._resolve_effort(prompt.options.reasoning_effort)

        cwd = os.getcwd()
        body: dict[str, Any] = {
            "config": {
                "workingDir": cwd,
                "date": date.today().isoformat(),
                "environment": f"{sys.platform}, Python {sys.version.split()[0]}",
                "structure": [],
                "isGitRepo": False,
                "currentBranch": "",
                "mainBranch": "",
                "gitStatus": "",
                "recentCommits": [],
            },
            "memory": None,
            "taste": None,
            "skills": None,
            "params": {
                "model": self.cc_model_id,
                "messages": messages,
                "tools": tools,
                "system": system_text,
                "max_tokens": max_tokens,
                "temperature": 0.3,
                "stream": True,
            },
            "threadId": str(uuid.uuid4()),
        }
        if effort:
            body["params"]["reasoning_effort"] = effort

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {key}",
            "x-command-code-version": COMMAND_CODE_CLI_VERSION,
            "x-cli-environment": "production",
            "x-project-slug": project_slug_from_path(cwd),
            "x-taste-learning": "true",
            "x-co-flag": "false",
        }

        url = f"{_api_base()}/alpha/generate"
        timeout = httpx.Timeout(connect=30, read=600, write=60, pool=30)
        collected_tool_calls: list[llm.ToolCall] = []

        try:
            with httpx.Client(timeout=timeout) as client:
                with client.stream("POST", url, json=body, headers=headers) as resp:
                    if resp.status_code != 200:
                        err_body = resp.read().decode("utf-8", "replace")
                        detail = None
                        try:
                            parsed: Any = json.loads(err_body)
                            detail = cc_error_message(parsed)
                        except json.JSONDecodeError:
                            pass
                        safe_detail = redact_secrets(
                            detail or err_body[:500] or "Provider returned an error"
                        )
                        raise llm.ModelError(
                            f"Command Code API error {resp.status_code}: {safe_detail}"
                        )

                    for line in resp.iter_lines():
                        event = parse_stream_line(line)
                        if event is None:
                            continue
                        event_type = event.get("type")
                        if event_type == "text-delta":
                            yield StreamEvent(type="text", chunk=str(event.get("text") or ""))
                        elif event_type == "reasoning-delta":
                            yield StreamEvent(type="reasoning", chunk=str(event.get("text") or ""))
                        elif event_type == "tool-call":
                            tool_id = str(event.get("toolCallId") or "")
                            tool_name = str(event.get("toolName") or "")
                            raw_input = event.get(
                                "input",
                                event.get("args", event.get("arguments")),
                            )
                            args = _parse_tool_input(raw_input)
                            yield StreamEvent(
                                type="tool_call_name",
                                chunk=tool_name,
                                tool_call_id=tool_id,
                            )
                            yield StreamEvent(
                                type="tool_call_args",
                                chunk=json.dumps(args, ensure_ascii=False),
                                tool_call_id=tool_id,
                            )
                            # Registers the call with the chain so llm can
                            # execute the tool and re-prompt (stream events
                            # alone only assemble response messages).
                            if tool_id and tool_name:
                                collected_tool_calls.append(
                                    llm.ToolCall(
                                        tool_call_id=tool_id,
                                        name=tool_name,
                                        arguments=args,
                                    )
                                )
                        elif event_type == "finish":
                            _set_usage(response, event)
                            break
                        elif event_type == "error":
                            message = (
                                cc_error_message(
                                    event.get("error") or event.get("message")
                                )
                                or "Stream error"
                            )
                            raise llm.ModelError(redact_secrets(message))

                    for tool_call in collected_tool_calls:
                        response.add_tool_call(tool_call)
        except llm.ModelError:
            raise
        except Exception as ex:  # noqa: BLE001 - surface as ModelError
            raise llm.ModelError(redact_secrets(str(ex))) from ex


# ──────────────────────────────────────────────────────────────────────────
# Plugin hooks.
# ──────────────────────────────────────────────────────────────────────────

@llm.hookimpl
def register_models(register, model_aliases):
    models, source, warning = load_commandcode_models()
    if warning:
        print(f"[commandcode] {redact_secrets(warning)}", file=sys.stderr)
    for catalog_entry in models:
        register(CommandCodeModel(catalog_entry))


@llm.hookimpl
def register_commands(cli):
    @cli.command(name="commandcode-models")
    @click.option(
        "--refresh",
        is_flag=True,
        help="Force a live refresh of the Command Code model catalog",
    )
    @click.option(
        "--json",
        "json_output",
        is_flag=True,
        help="Output the result as JSON",
    )
    def commandcode_models(refresh, json_output):
        """List Command Code models and catalog diagnostics."""
        models, source, warning = load_commandcode_models(refresh=refresh)

        if json_output:
            click.echo(
                json.dumps(
                    {
                        "source": source,
                        "model_count": len(models),
                        "cache_path": str(_models_cache_path()),
                        "endpoint": _redact_endpoint(_models_url()),
                        "warning": warning,
                        "models": [m["id"] for m in models],
                    },
                    indent=2,
                )
            )
            if warning:
                click.echo(redact_secrets(warning), err=True)
            return

        click.echo(f"source: {source}")
        click.echo(f"model count: {len(models)}")
        click.echo(f"cache path: {_models_cache_path()}")
        click.echo(f"endpoint: {_redact_endpoint(_models_url())}")
        if warning:
            click.echo(f"warning: {redact_secrets(warning)}")
        for catalog_entry in models:
            click.echo(f"  commandcode/{catalog_entry['id']}")
