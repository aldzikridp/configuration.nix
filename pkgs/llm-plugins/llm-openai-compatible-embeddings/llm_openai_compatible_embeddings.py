"""LLM plugin for OpenAI-compatible HTTP embedding APIs (Ollama, LM Studio,
vLLM, TEI, Jina, Together, Groq, ...). Configured via:

    ~/.config/io.datasette.llm/openai-compatible-embeddings.yaml

(that path is ``llm.user_dir() / "openai-compatible-embeddings.yaml"``).

Example config::

    servers:
      - name: ollama
        base_url: http://localhost:11434/v1
        no_auth: true
        models:
          - nomic-embed-text
          - model: mxbai-embed-large
            aliases: [mxbai]
            dimensions: 1024
      - name: lmstudio
        base_url: http://localhost:1234/v1
        api_key: lm-studio
        models: [text-embedding-nomic-embed-text-v1.5]
      - name: jina
        base_url: https://api.jina.ai/v1
        api_key_env: JINA_API_KEY
        models: [jina-embeddings-v3]
      - name: mycloud
        base_url: https://example.com/v1
        llm_key: mycloud
        models:
          - model: text-embedding-3-small
            aliases: [small]

Key sources, in order: ``api_key`` (literal) -> ``llm_key`` (``llm keys set
<name>``) -> ``api_key_env`` -> none if ``no_auth: true`` -> error otherwise.

Each model is registered under the id ``<name>/<model>``.

Use::

    llm embed-models list
    llm embed -m ollama/nomic-embed-text -c "hello world"
"""

from __future__ import annotations

import base64
import os
import struct
import sys
from typing import Any, Iterable, Iterator, List, Optional, Union

import httpx
import llm
import yaml

__version__ = "0.1.0"

CONFIG_FILENAME = "openai-compatible-embeddings.yaml"
DEFAULT_BATCH_SIZE = 100
DEFAULT_TIMEOUT = 30.0


def _warn(message: str) -> None:
    print(f"llm-openai-compatible-embeddings: {message}", file=sys.stderr)


def _parse_model(entry: Any, context: str) -> Optional[dict]:
    """Normalize one model entry. Never raises; returns None on invalid."""
    if isinstance(entry, str):
        if not entry.strip():
            _warn(f"{context}: empty model id")
            return None
        return {"model": entry.strip(), "aliases": [], "dimensions": None, "batch_size": None}
    if not isinstance(entry, dict):
        _warn(f"{context}: expected a string or mapping, got {type(entry).__name__}")
        return None
    model = entry.get("model")
    if not isinstance(model, str) or not model.strip():
        _warn(f"{context}: missing or invalid 'model'")
        return None
    aliases = entry.get("aliases") or []
    if not isinstance(aliases, list):
        _warn(f"{context}: 'aliases' must be a list, ignoring it")
        aliases = []
    aliases = [a for a in aliases if isinstance(a, str)]
    dimensions = entry.get("dimensions")
    if dimensions is not None and not isinstance(dimensions, int):
        _warn(f"{context}: 'dimensions' must be an integer, ignoring it")
        dimensions = None
    batch_size = entry.get("batch_size")
    if batch_size is not None and not isinstance(batch_size, int):
        _warn(f"{context}: 'batch_size' must be an integer, ignoring it")
        batch_size = None
    return {"model": model.strip(), "aliases": aliases,
            "dimensions": dimensions, "batch_size": batch_size}


def _parse_server(entry: Any, context: str) -> Optional[dict]:
    """Normalize one server entry. Never raises; returns None on invalid."""
    if not isinstance(entry, dict):
        _warn(f"{context}: expected a mapping, got {type(entry).__name__}")
        return None
    name = entry.get("name")
    if not isinstance(name, str) or not name.strip():
        _warn(f"{context}: missing or invalid 'name' (model-id prefix)")
        return None
    name = name.strip()
    base_url = entry.get("base_url")
    if not isinstance(base_url, str) or not base_url.strip():
        _warn(f"{context}: missing or invalid 'base_url'")
        return None
    base_url = base_url.rstrip("/")

    api_key = entry.get("api_key")
    if api_key is not None and not isinstance(api_key, str):
        _warn(f"{context}: 'api_key' must be a string, ignoring it")
        api_key = None
    llm_key = entry.get("llm_key")
    if llm_key is not None and not isinstance(llm_key, str):
        _warn(f"{context}: 'llm_key' must be a string, ignoring it")
        llm_key = None
    api_key_env = entry.get("api_key_env")
    if api_key_env is not None and not isinstance(api_key_env, str):
        _warn(f"{context}: 'api_key_env' must be a string, ignoring it")
        api_key_env = None

    no_auth = bool(entry.get("no_auth", False))
    verify_tls = bool(entry.get("verify_tls", True))

    timeout_seconds = entry.get("timeout_seconds", DEFAULT_TIMEOUT)
    if not isinstance(timeout_seconds, (int, float)) or timeout_seconds <= 0:
        _warn(f"{context}: invalid 'timeout_seconds', using {DEFAULT_TIMEOUT}")
        timeout_seconds = DEFAULT_TIMEOUT

    extra_headers = entry.get("extra_headers")
    if extra_headers is not None and not isinstance(extra_headers, dict):
        _warn(f"{context}: 'extra_headers' must be a mapping, ignoring it")
        extra_headers = None
    elif extra_headers is not None:
        extra_headers = {str(k): str(v) for k, v in extra_headers.items()}

    server_batch = entry.get("batch_size")
    if server_batch is not None and not isinstance(server_batch, int):
        _warn(f"{context}: 'batch_size' must be an integer, ignoring it")
        server_batch = None

    raw_models = entry.get("models")
    if raw_models is None:
        _warn(f"{context}: missing 'models' list")
        return None
    if not isinstance(raw_models, list):
        _warn(f"{context}: 'models' must be a list")
        return None

    models: List[dict] = []
    for i, m in enumerate(raw_models):
        model = _parse_model(m, f"{context} models[{i}]")
        if model is not None:
            if model["batch_size"] is None:
                model["batch_size"] = server_batch
            models.append(model)
    if not models:
        _warn(f"{context}: no valid models configured")
        return None

    return {
        "name": name, "base_url": base_url, "api_key": api_key, "llm_key": llm_key,
        "api_key_env": api_key_env, "no_auth": no_auth, "verify_tls": verify_tls,
        "timeout_seconds": float(timeout_seconds), "extra_headers": extra_headers,
        "models": models,
    }


def _load_config() -> List[dict]:
    """Load servers from the YAML config file.

    Returns a list of normalized server dicts. Never raises: a missing or
    broken config file just warns on stderr and registers no models.
    """
    path = llm.user_dir() / CONFIG_FILENAME
    if not path.exists():
        _warn(f"config file not found: {path} (no embedding models registered)")
        return []
    try:
        data = yaml.safe_load(path.read_text())
    except Exception as e:
        _warn(f"failed to parse {path}: {e}")
        return []
    if data is None:
        return []
    if not isinstance(data, dict):
        _warn(f"{path}: expected a mapping with a 'servers' key, got {type(data).__name__}")
        return []
    raw_servers = data.get("servers")
    if raw_servers is None:
        _warn(f"{path}: missing 'servers' key")
        return []
    if not isinstance(raw_servers, list):
        _warn(f"{path}: 'servers' must be a list")
        return []
    servers: List[dict] = []
    for i, srv in enumerate(raw_servers):
        server = _parse_server(srv, f"{path} servers[{i}]")
        if server is not None:
            servers.append(server)
    return servers


class OpenAICompatibleEmbeddingModel(llm.EmbeddingModel):
    """Embedding model backed by an OpenAI-compatible /embeddings endpoint."""

    batch_size = DEFAULT_BATCH_SIZE
    supports_text = True
    supports_binary = False

    def __init__(self, model_id, api_model_id, server_name, base_url,
                 api_key=None, llm_key=None, api_key_env=None, no_auth=False,
                 verify_tls=True, timeout_seconds=DEFAULT_TIMEOUT,
                 extra_headers=None, dimensions=None, batch_size=None):
        self.model_id = model_id          # user-facing: <name>/<model>
        self.api_model_id = api_model_id  # what the server expects
        self.server_name = server_name
        self.base_url = base_url
        self.api_key = api_key
        self.llm_key = llm_key
        self.api_key_env = api_key_env
        self.no_auth = no_auth
        self.verify_tls = verify_tls
        self.timeout_seconds = timeout_seconds
        self.extra_headers = extra_headers or {}
        self.dimensions = dimensions
        if batch_size is not None:
            self.batch_size = batch_size

    def _resolve_key(self) -> Optional[str]:
        if self.api_key is not None:
            return self.api_key
        if self.llm_key:
            value = llm.get_key(key_alias=self.llm_key)
            if value:
                return value
        if self.api_key_env:
            value = os.environ.get(self.api_key_env)
            if value:
                return value
        if self.no_auth:
            return None
        raise llm.NeedsKeyException(
            f"No API key for server '{self.server_name}'. Configure api_key, "
            f"llm_key, api_key_env, or no_auth: true in "
            f"{llm.user_dir() / CONFIG_FILENAME}.")

    def embed_batch(self, items: Iterable[Union[str, bytes]]) -> Iterator[List[float]]:
        items = list(items)
        if not items:
            return iter(())

        payload = {"model": self.api_model_id, "input": items,
                   "encoding_format": "float"}
        if self.dimensions:
            payload["dimensions"] = self.dimensions

        headers = {"Content-Type": "application/json"}
        headers.update(self.extra_headers)
        key = self._resolve_key()
        if key is not None:
            headers["Authorization"] = f"Bearer {key}"

        url = f"{self.base_url}/embeddings"
        try:
            response = httpx.post(url, json=payload, headers=headers,
                                  verify=self.verify_tls,
                                  timeout=httpx.Timeout(self.timeout_seconds,
                                                        connect=self.timeout_seconds))
        except httpx.HTTPError as exc:
            raise llm.ModelError(
                f"embeddings request to {url} failed: {exc}") from exc

        if response.status_code != 200:
            raise llm.ModelError(
                f"embeddings endpoint {url} returned HTTP "
                f"{response.status_code}: {response.text[:500]}")

        try:
            data = response.json()
        except ValueError as exc:
            raise llm.ModelError(
                f"embeddings endpoint {url} returned non-JSON: "
                f"{response.text[:200]}") from exc

        rows = data.get("data")
        if not isinstance(rows, list):
            raise llm.ModelError("embeddings response has no 'data' array")

        # Restore input order; some servers reorder or omit 'index'.
        rows = sorted(rows, key=lambda r: r.get("index", 0) if isinstance(r, dict) else 0)
        if len(rows) != len(items):
            raise llm.ModelError(
                f"embeddings endpoint returned {len(rows)} vectors "
                f"for {len(items)} inputs")

        results = []
        for row in rows:
            if not isinstance(row, dict):
                raise llm.ModelError("embeddings response contained a non-object entry")
            results.append(self._decode_vector(row.get("embedding")))
        return iter(results)

    @staticmethod
    def _decode_vector(vector: Any) -> List[float]:
        if isinstance(vector, list):
            return [float(x) for x in vector]
        if isinstance(vector, str):
            # Base64 little-endian float32. Rare because we request float,
            # but some servers ignore encoding_format.
            try:
                raw = base64.b64decode(vector)
                raw = raw[: (len(raw) // 4) * 4]
                return list(struct.unpack(f"<{len(raw) // 4}f", raw))
            except Exception as exc:
                raise llm.ModelError(f"failed to decode base64 embedding: {exc}") from exc
        raise llm.ModelError("embedding entry had no usable 'embedding' field")


@llm.hookimpl
def register_embedding_models(register):
    """Register the embedding models the user listed in the config file."""
    for server in _load_config():
        name = server["name"]
        for entry in server["models"]:
            api_model_id = entry["model"]
            register(
                OpenAICompatibleEmbeddingModel(
                    model_id=f"{name}/{api_model_id}",
                    api_model_id=api_model_id,
                    server_name=name,
                    base_url=server["base_url"],
                    api_key=server["api_key"],
                    llm_key=server["llm_key"],
                    api_key_env=server["api_key_env"],
                    no_auth=server["no_auth"],
                    verify_tls=server["verify_tls"],
                    timeout_seconds=server["timeout_seconds"],
                    extra_headers=server["extra_headers"],
                    dimensions=entry["dimensions"],
                    batch_size=entry["batch_size"],
                ),
                aliases=tuple(entry["aliases"]),
            )