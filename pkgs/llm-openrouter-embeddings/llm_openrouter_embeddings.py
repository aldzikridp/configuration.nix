"""LLM plugin for OpenRouter embedding models.

The list of embedding models is NOT hard-coded: the user provides the model
IDs themselves in a YAML config file:

    ~/.config/io.datasette.llm/openrouter-embeddings.yaml

(That path is ``llm.user_dir() / "openrouter-embeddings.yaml"``.)

Example config::

    # Simple form: just a model ID.
    - openai/text-embedding-3-small

    # Extended form with optional aliases / dimensions / batch_size.
    - model: voyage/voyage-3
      aliases:
        - openrouter-voyage-3
      batch_size: 50
    - model: openai/text-embedding-3-large
      dimensions: 1024
      batch_size: 25

Each model is registered with ``llm`` under the id ``openrouter/<model>``
(the ``openrouter/`` prefix avoids collisions with llm's built-in OpenAI
embedding models such as ``text-embedding-3-small``).

Requires an OpenRouter API key, which is resolved by ``llm``:

    llm keys set openrouter
    # or: export OPENROUTER_API_KEY=...

Use:

    llm embed-models list
    llm embed -m openrouter/openai/text-embedding-3-small -c "hello world"
"""

from __future__ import annotations

import sys
from typing import Iterable, Iterator, List, Optional, Union

import llm
import yaml
from openai import OpenAI

__version__ = "0.1.0"

# OpenRouter is OpenAI-compatible, so the embeddings endpoint is
# <base_url>/embeddings.
BASE_URL = "https://openrouter.ai/api/v1"

# Config file name, stored inside llm's user directory
# (~/.config/io.datasette.llm/ on Linux).
CONFIG_FILENAME = "openrouter-embeddings.yaml"

# Default batch size when the user does not override it per model.
DEFAULT_BATCH_SIZE = 100


def _warn(message: str) -> None:
    print(f"llm-openrouter-embeddings: {message}", file=sys.stderr)


def _load_config() -> List[dict]:
    """Load the user's embedding model list from the YAML config file.

    Returns a list of normalized dicts::

        {"model": str, "aliases": [str], "dimensions": int|None,
         "batch_size": int|None}

    Never raises: a missing/broken config file just results in an empty
    list (the plugin registers no models) and a warning on stderr.
    """
    path = llm.user_dir() / CONFIG_FILENAME
    if not path.exists():
        _warn(f"config file not found: {path} (no OpenRouter embedding models registered)")
        return []

    try:
        data = yaml.safe_load(path.read_text())
    except Exception as e:
        _warn(f"failed to parse {path}: {e}")
        return []

    if data is None:
        return []
    if isinstance(data, dict):
        # Tolerate a single mapping instead of a list of mappings.
        data = [data]
    if not isinstance(data, list):
        _warn(f"{path}: expected a YAML list, got {type(data).__name__}")
        return []

    models: List[dict] = []
    for entry in data:
        if isinstance(entry, str):
            models.append(
                {
                    "model": entry,
                    "aliases": [],
                    "dimensions": None,
                    "batch_size": None,
                }
            )
            continue
        if not isinstance(entry, dict):
            _warn(f"ignoring invalid config entry: {entry!r}")
            continue
        model = entry.get("model")
        if not isinstance(model, str) or not model.strip():
            _warn(f"ignoring config entry without a valid 'model': {entry!r}")
            continue
        aliases = entry.get("aliases") or []
        if not isinstance(aliases, list):
            aliases = []
        aliases = [a for a in aliases if isinstance(a, str)]
        dimensions = entry.get("dimensions")
        if dimensions is not None and not isinstance(dimensions, int):
            _warn(f"ignoring non-integer dimensions for {model!r}")
            dimensions = None
        batch_size = entry.get("batch_size")
        if batch_size is not None and not isinstance(batch_size, int):
            _warn(f"ignoring non-integer batch_size for {model!r}")
            batch_size = None
        models.append(
            {
                "model": model.strip(),
                "aliases": aliases,
                "dimensions": dimensions,
                "batch_size": batch_size,
            }
        )
    return models


class OpenRouterEmbeddingModel(llm.EmbeddingModel):
    """Embedding model backed by the OpenRouter embeddings API."""

    needs_key = "openrouter"
    key_env_var = "OPENROUTER_API_KEY"
    batch_size = DEFAULT_BATCH_SIZE

    def __init__(
        self,
        model_id: str,
        api_model_id: str,
        dimensions: Optional[int] = None,
        batch_size: Optional[int] = None,
    ):
        # model_id is what the user types after `llm embed -m` (with the
        # openrouter/ prefix). api_model_id is what OpenRouter expects.
        self.model_id = model_id
        self.api_model_id = api_model_id
        self.dimensions = dimensions
        if batch_size is not None:
            self.batch_size = batch_size

    def embed_batch(
        self, items: Iterable[Union[str, bytes]]
    ) -> Iterator[List[float]]:
        items = list(items)
        if not items:
            return iter(())

        kwargs = {
            "model": self.api_model_id,
            "input": items,
            # openai>=2.x defaults to base64 when omitted; some OpenRouter
            # providers (e.g. Nvidia) only accept float. Always request float.
            "encoding_format": "float",
        }
        if self.dimensions:
            kwargs["dimensions"] = self.dimensions

        client = OpenAI(base_url=BASE_URL, api_key=self.get_key())
        results = client.embeddings.create(**kwargs).data
        return ([float(r) for r in result.embedding] for result in results)


@llm.hookimpl
def register_embedding_models(register):
    """Register the models the user listed in the YAML config file."""
    for entry in _load_config():
        api_model_id = entry["model"]
        register(
            OpenRouterEmbeddingModel(
                f"openrouter/{api_model_id}",
                api_model_id,
                dimensions=entry["dimensions"],
                batch_size=entry["batch_size"],
            ),
            aliases=tuple(entry["aliases"]),
        )
