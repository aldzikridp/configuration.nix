# llm plugins — writing & porting guide

This directory vendors (or fetches) the custom [`llm`](https://llm.datasette.io/)
plugins used by this configuration, and wires them into a single `llm`
environment via `home/llm.nix`.

This guide documents:

1. **How `llm` plugins work** — entry points and hooks.
2. **How to write one** — the file layout, Nix derivation, and wiring.
3. **How to port one** — from a pi extension (provider) and from aichat
   bash tools.

The definitive API reference is llm's own source, which ships inside the
derivation (`llm/models.py`, `llm/parts.py`, `llm/hookspecs.py`,
`llm/default_plugins/openai_models.py`). This repo pins **llm 0.32** via
the `pythonPackagesExtensions` override in `home/llm.nix`; the snippets
below target that version.

---

## 1. Inventory

| Directory | Kind | Hook | Source | Notes |
| --- | --- | --- | --- | --- |
| `llm-ctx7` | tool | `register_tools` | vendored | `ctx7_search`, shells out to the `ctx7` CLI |
| `llm-wikipedia` | tool | `register_tools` | vendored | `search_wikipedia`, native `urllib` |
| `llm-fetch-url` | tool | `register_tools` | vendored | `fetch_url`, uses `trafilatura` |
| `llm-fetch-curl` | tool | `register_tools` | vendored | `fetch_url`, shells out to `curl`+`pandoc`+`sed` (orphaned) |
| `llm-file-tools` | tool | `register_tools` | vendored | 13 file tools + `FileTools` toolbox |
| `llm-openrouter-embeddings` | embedding models | `register_embedding_models` | vendored | config-driven OpenRouter embeddings |
| `llm-openai-compatible-embeddings` | embedding models | `register_embedding_models` | vendored | config-driven OpenAI-compatible endpoints (Ollama, LM Studio, vLLM, ...) |
| `llm-tools-rag` | tool (toolbox) | `register_tools` | `fetchFromGitHub` | RAG search over llm's embeddings DB |
| `llm-commandcode` | chat models | `register_models` + `register_commands` | vendored | ported from `pi-commandcode-provider` |

---

## 2. How llm discovers plugins

`llm` uses [`pluggy`](https://pluggy.readthedocs.io/) with the entry-point
group **`llm`**. When a Python package is installed into the same environment
as `llm`, `llm` imports every module declared in that group and runs any
`@llm.hookimpl` functions it finds.

```toml
# pyproject.toml
[project.entry-points.llm]
myplugin = "llm_myplugin"
```

`llm plugins` lists the installed plugins (by their distribution name,
e.g. `llm-commandcode`) and which hooks each one implements. The entry-point
left-hand side is the key llm's plugin registry uses internally.

The available hooks (from `llm/hookspecs.py`):

| Hook signature | Purpose |
| --- | --- |
| `register_models(register, model_aliases)` | register chat model instances (`llm.Model` / `llm.KeyModel`) |
| `register_embedding_models(register)` | register `llm.EmbeddingModel` instances |
| `register_tools(register)` | register callable tools or `llm.Toolbox` classes |
| `register_commands(cli)` | add extra `llm ...` CLI commands (click) |
| `register_template_loaders(register)` | add `llm -t` template loaders |
| `register_fragment_loaders(register)` | add prompt fragment loaders |

> This repo uses the first four. Template/fragment loaders are out of scope here.

---

## 3. File layout of a vendored plugin

Every vendored plugin is a directory under `pkgs/llm-plugins/` containing:

```
llm-<name>/
├── default.nix            # Nix derivation (buildPythonPackage)
├── pyproject.toml         # package metadata + the [project.entry-points.llm] entry point
├── llm_<name>.py          # the plugin module (the @llm.hookimpl code)
└── README.md              # optional, but recommended
```

- `src = ./.;` means the **whole directory** is the source tree;
  `buildPythonPackage` only needs `pyproject.toml` + the module file. The
  `default.nix` and `README.md` are ignored.
- One plugin = one module + one entry point. Keep it a single file unless it
  genuinely grows too large (e.g. `llm-commandcode` is one ~600-line module).

---

## 4. Nix derivation (`default.nix`)

```nix
{ lib, buildPythonPackage, llm, setuptools, mydependency }:

buildPythonPackage rec {
  pname = "llm-myplugin";
  version = "0.1.0";
  pyproject = true;

  # Vendor the files next to this default.nix.
  src = ./.;

  build-system = [ setuptools ];

  # llm must be propagated because the module does `import llm`. Any other
  # runtime import (httpx, yaml, trafilatura, ...) is propagated too, so it
  # lands in the same python env the plugin is installed into.
  propagatedBuildInputs = [ llm mydependency ];

  # Vendored plugins don't ship tests; the nixpkgs build sandbox can't run
  # most of them anyway (network, CLI tools, etc).
  doCheck = false;

  # The importable module name (no .py). Guards against packaging mistakes.
  pythonImportsCheck = [ "llm_myplugin" ];

  meta = {
    description = "...";
    homepage = "...";
    license = lib.licenses.mit;
    # Do NOT set `mainProgram = null` — newer nixpkgs propagates it into the
    # env as NIX_MAIN_PROGRAM and env values cannot be null. A plugin has no
    # main program, so omit mainProgram entirely.
  };
}
```

Notes:

- `propagatedBuildInputs` (not `buildInputs`) — a plugin's dependencies must
  be visible at *runtime*, so they propagate into the env that `llm` runs in.
  (`llm-tools-rag` uses the equivalent `dependencies = [...]` attribute —
  same effect in current nixpkgs.)
- `doCheck = false` is the convention for every plugin here: tests aren't
  vendored, and the sandbox has no network.
- `license` — set it from the actual project. `llm-tools-rag` deliberately
  omits it because upstream's metadata is contradictory (MIT vs Apache-2.0,
  no LICENSE file). When in doubt, omit and leave a comment.

Fetched plugins are identical except for `src`:

```nix
src = fetchFromGitHub {
  owner = "someuser";
  repo = "llm-something";
  tag = version;
  hash = "sha256-...";
};
```

Use `nix flake check` to fail fast if the hash/deps are wrong (see §8).

---

## 5. Wiring into `home/llm.nix`

There are three edits, each in a different part of the `let` block:

**Step A — build the derivation** (alongside the other `callPackage`s):

```nix
llm-myplugin-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-myplugin/default.nix { };
```

**Step B — add it to `myPython`'s `packageOverrides`** so `withPackages` can
resolve `ps.llm-myplugin` by name:

```nix
myPython = pkgs'.python3.override {
  packageOverrides = self: super: {
    # ...
    llm-myplugin = llm-myplugin-pkg;
  };
};
```

**Step C — include it in the env**:

```nix
myLlmEnv = myPython.withPackages (ps: with ps; [
  llm
  # ...
  llm-myplugin
]);
```

> `llm` discovers plugins via `importlib.metadata`, so simply being present
> in the env is enough — no `llm.withPlugins { }` is used here (see the big
> comment block at the top of `home/llm.nix` for why).

---

## 6. Writing a tool plugin

The simplest plugin kind. A tool is a plain Python function; llm builds the
tool's JSON schema from the **type hints** and uses the **docstring** as the
description.

```python
"""llm plugin providing the roll_dice tool."""

import random

import llm

__version__ = "0.1.0"


def roll_dice(sides: int = 6) -> str:
    """Roll a dice with the given number of sides.

    Args:
        sides: Number of sides on the dice (default 6).
    """
    return str(random.randint(1, sides))


@llm.hookimpl
def register_tools(register):
    register(roll_dice)
```

Then:

```sh
llm -m <any tool-capable model> -T roll_dice "roll two dice" --td
```

Rules of thumb (all visible in `llm-ctx7`, `llm-wikipedia`, `llm-fetch-url`):

- **Return a string.** llm passes it to the model verbatim.
- **Signal failure with an `"error: ..."` string**, never by raising. An
  unhandled exception becomes a tool error result, but an explicit
  `"error: reason"` string gives the model more useful context.
- **Prefer native Python** (`urllib`, `trafilatura`) over shelling out.
  Reserve `subprocess` for CLIs that have no Python library (`ctx7`).
- If you shell out to a CLI (`ctx7`, `ripgrep`, `git`), that binary must be
  on `PATH` at runtime — add it to `home.packages` / `environment.systemPackages`
  separately (the derivation can't provide it).

### Toolbox (multiple related tools)

Subclass `llm.Toolbox`; each public method becomes a tool named
`ClassName_method`, and registering the class lets users enable all of them
at once with `-T ClassName`:

```python
class CalcTools(llm.Toolbox):
    def add(self, a: float, b: float) -> str:
        "Add two numbers."
        return str(a + b)

    def multiply(self, a: float, b: float) -> str:
        "Multiply two numbers."
        return str(a * b)


@llm.hookimpl
def register_tools(register):
    register(CalcTools)   # exposes `-T CalcTools`, tools CalcTools_add / CalcTools_multiply
```

See `llm-file-tools` for a real example: it registers the individual
functions (`-T read_file`) **and** the `FileTools` toolbox (`-T FileTools`).

---

## 7. Writing a chat model plugin

The hardest kind, and what most ports boil down to. The skeleton:

```python
"""llm plugin providing models from some-provider."""

from __future__ import annotations

from typing import Iterator, Optional, Union

import llm
from llm.parts import StreamEvent

__version__ = "0.1.0"


class MyProviderModel(llm.KeyModel):
    # KeyModel resolves the API key (see below) and passes it to execute().
    needs_key = "myprovider"              # alias for `llm keys set myprovider`
    key_env_var = "MYPROVIDER_API_KEY"

    # Extra options settable with `-o key value`.
    class Options(llm.Options):
        temperature: Optional[float] = None
        max_tokens: Optional[int] = None

    def __init__(self, model_id: str, api_model_id: str):
        self.model_id = model_id          # what the user types after -m
        self.api_model_id = api_model_id  # what the API expects
        self.can_stream = True
        self.supports_tools = True
        # self.supports_schema = False    # only if the API does JSON schema
        # self.attachment_types = {...}   # MIME types accepted as attachments

    def execute(
        self,
        prompt: llm.Prompt,
        stream: bool,
        response: llm.Response,
        conversation: llm.Conversation | None,
        key: str | None,
    ) -> Iterator[Union[str, StreamEvent]]:
        # 1. Build the provider request from prompt.messages / prompt.tools
        #    (see "Reading the prompt" below).
        # 2. POST and iterate the response stream.
        # 3. yield StreamEvents, record usage and tool calls.

        yield StreamEvent(type="text", chunk="hello")

        # Token usage -> `llm logs` / response.usage()
        response.set_usage(input=10, output=1, details={"cache_read_tokens": 2})

        # Tool calls MUST also be registered here (see gotcha below).
        response.add_tool_call(
            llm.ToolCall(tool_call_id="call_1", name="some_tool", arguments={...})
        )


@llm.hookimpl
def register_models(register, model_aliases):
    for entry in fetch_catalog():  # your catalog logic
        register(
            MyProviderModel(f"myprovider/{entry['id']}", entry["id"]),
            aliases=(entry["id"],),  # optional
        )
```

### Key resolution

`llm.KeyModel.get_key()` already implements the standard hierarchy:
`llm keys set <needs_key>` → `key_env_var`. If you need extra fallbacks
(e.g. reading a provider's own auth file), override `get_key` and re-raise
`llm.NeedsKeyException` if nothing is found:

```python
def get_key(self, explicit_key=None):
    try:
        return super().get_key(explicit_key)
    except llm.NeedsKeyException:
        key = read_auth_file_fallback()
        if key:
            return key
        raise
```

### Streaming events

`execute()` is a generator. Yield either a plain `str` (legacy) or
`llm.parts.StreamEvent`:

| StreamEvent type | Meaning |
| --- | --- |
| `text` | a visible text chunk |
| `reasoning` | a thinking/chain-of-thought chunk |
| `tool_call_name` | the name of a tool the model wants to call |
| `tool_call_args` | the (JSON) arguments for that tool call |
| `tool_result` | a server-executed tool result |

Consecutive same-type events with the same `tool_call_id` are merged
automatically; leave `part_index=None` (the default) unless you need to pin
parts together.

### ⚠️ The tool-call gotcha

`tool_call_name` / `tool_call_args` events only assemble the response
**messages**. For llm's tool loop to actually *execute* the tool and
re-prompt the model, you must **also** call `response.add_tool_call(...)`:

```python
# from a streamed "tool-call" event:
yield StreamEvent(type="tool_call_name", chunk=name, tool_call_id=tool_id)
yield StreamEvent(type="tool_call_args", chunk=json.dumps(args), tool_call_id=tool_id)
response.add_tool_call(llm.ToolCall(tool_call_id=tool_id, name=name, arguments=args))
```

Skipping `add_tool_call` silently stops the chain after the first assistant
turn (the model's text prints, but the tool never runs). This is the single
most common model-plugin bug.

### Reading the prompt

`prompt.messages` is the canonical conversation — a list of
`llm.parts.Message(role=..., parts=[...])` where each part is one of:

| Part class | Where it appears | Relevant fields |
| --- | --- | --- |
| `TextPart` | user / assistant / system | `.text` |
| `AttachmentPart` | user (images, files) | `.attachment` (`llm.Attachment`: `.base64_content()`, `.resolve_type()`) |
| `ToolCallPart` | assistant | `.name`, `.arguments`, `.tool_call_id` |
| `ToolResultPart` | tool | `.name`, `.output`, `.tool_call_id`, `.exception` |
| `ReasoningPart` | assistant | `.text` (prior thinking — usually you should **not** replay it) |

Other prompt fields:

- `prompt.system` — system prompt string.
- `prompt.tools` — `list[llm.Tool]`; each has `.name`, `.description`,
  `.input_schema` (already a JSON Schema dict — no conversion needed).
- `prompt.options` — your `Options` instance (the `-o key value` values).

### Errors

Raise `llm.ModelError("message")` for provider errors; the CLI prints it
cleanly. Keep API keys out of error text (redact before raising).

---

## 8. Writing an embedding model plugin

Subclass `llm.EmbeddingModel` and implement `embed_batch`. Same `needs_key`
/ `key_env_var` mechanics as chat models.

```python
class MyEmbeddingModel(llm.EmbeddingModel):
    needs_key = "myprovider"
    key_env_var = "MYPROVIDER_API_KEY"
    batch_size = 100

    def __init__(self, model_id: str, api_model_id: str):
        self.model_id = model_id
        self.api_model_id = api_model_id

    def embed_batch(self, items):
        # Return an iterator of list[float], one per input item.
        ...


@llm.hookimpl
def register_embedding_models(register):
    register(MyEmbeddingModel("myprovider/text-embed-3", "text-embed-3"))
```

`llm-openrouter-embeddings` is the worked example (config-driven model list,
aliases, per-model `dimensions`/`batch_size`).

---

## 9. Porting guides

### 9.1 Porting a pi extension (model provider)

`llm-commandcode` is a complete, working port of
[`pi-commandcode-provider`](https://github.com/patlux/pi-commandcode-provider).
Read it as the reference. The concept map:

| pi extension concept | llm equivalent |
| --- | --- |
| `registerProvider(name, config)` in the extension entry point | `@llm.hookimpl def register_models(register, model_aliases)` — register one `llm.KeyModel` per catalog entry |
| `ProviderConfig.models` (dynamic catalog) | one `KeyModel` instance per model, `model_id = "provider/{id}"` |
| `streamSimple(model, context, options)` returning an `AssistantMessageEventStream` | `KeyModel.execute(prompt, stream, response, conversation, key)` — a generator |
| `text_delta` event | `yield StreamEvent(type="text", chunk=...)` |
| `thinking_delta` / `reasoning-delta` event | `yield StreamEvent(type="reasoning", chunk=...)` |
| `toolcall_start` / `toolcall_end` events | `yield StreamEvent(type="tool_call_name" / "tool_call_args", ...)` **plus** `response.add_tool_call(llm.ToolCall(...))` |
| `done` event + `usage` | `response.set_usage(input=..., output=..., details=...)`, then return |
| `error` event / thrown error | `raise llm.ModelError(message)` |
| `getApiKey` / oauth / `auth.json` | `needs_key` + `key_env_var` (+ `llm keys set`) and, if desired, a `get_key()` override for auth-file fallback |
| `registerCommand("x-refresh" / "x-status")` | `@llm.hookimpl def register_commands(cli)` with `@cli.command(name="x-models")` |
| model discovery + cache | the same logic, called synchronously from `register_models` (llm is a one-shot CLI: cache-first with a TTL, don't fetch on every invocation) |

Things that have **no llm equivalent and should be dropped**:

- Browser OAuth `/login` flow → use `llm keys set <name>`.
- Per-request cost/pricing display → llm has no dollar-cost UI.
- Context-overflow error normalization → pi-specific.
- Runtime provider re-registration/refresh → llm re-registers models fresh on
  every CLI invocation; an explicit `llm provider-models --refresh` command
  covers the "refresh the cache" case.

**Porting recipe** (mirroring how `llm-commandcode` was built):

1. Copy the provider's **wire format** code verbatim into Python:
   - the request-body builder (messages + tools + params serialization),
   - the SSE line parser and event dispatcher,
   - the catalog fetch + cache parser,
   - any static tables (model efforts, input modalities, pricing).
2. Replace the host-side message types with `prompt.messages` parts
   (§7). For a non-OpenAI API, you usually map `TextPart`/`AttachmentPart`
   → provider message content, `ToolCallPart`/`ToolResultPart` → provider
   tool messages, and **drop `ReasoningPart`** (private reasoning is not
   replayed on follow-up turns).
3. Replace the event stream with `StreamEvent` yields + `set_usage` +
   `add_tool_call`.
4. Replace auth with `needs_key` / `key_env_var` (+ fallback override).
5. Add a `register_commands` CLI command for diagnostics (`--json` output is
   cheap and useful).
6. Test against the provider's *test fixtures* via a local mock server
   (§10.3) — the pi extension's own test suite doubles as your expected
   serialization spec.

### 9.2 Porting an aichat bash tool

`llm-ctx7`, `llm-wikipedia`, and `llm-fetch-url` are ports of aichat
(https://github.com/sigoden/aichat) bash tool scripts. Recipe:

1. Turn the bash script into one Python function. The **function name** is the
   tool name, the **docstring** the description, the **typed parameters** the
   schema.
2. Prefer native Python over `curl`/`pandoc`/`sed`:
   - `search_wikipedia.sh` → `urllib` (llm-wikipedia)
   - `fetch_url_via_curl.sh` → `trafilatura` (llm-fetch-url)
   - only keep `subprocess` when there's no library (`ctx7`).
3. Return strings; report failures as `"error: ..."`.
4. Keep a module docstring that records *what the original did* and *what
   changed* — the `llm-fetch-url` module header is the model to copy.

---

## 10. Testing & verification

### 10.1 Evaluate + build

```sh
nix flake check
```

This only *evaluates*. To actually exercise the plugin, build the llm env and
run the binary (the env is an input of the `llm-with-custom-plugins` wrapper):

```sh
# find the wrapper drv, then realise its python-env input
WRAPPER=$(nix eval --raw --impure --expr '
  let f = builtins.getFlake (toString /home/master-x/configuration.nix);
      p = f.outputs.nixosConfigurations."EVA-02".config.home-manager.users.master-x.home.packages;
  in (builtins.head (builtins.filter
      (x: (builtins.tryEval x).success &&
          (builtins.match ".*llm-with-custom-plugins" (builtins.tryEval x).value.outPath) != null)
      p)).drvPath')
ENV=$(nix-store -q --references "$WRAPPER" | grep 'python3-.*-env.drv')
nix-store -r "$ENV"
```

Then point `PATH` (or a variable) at `<env>/bin/llm`.

### 10.2 Smoke checks

```sh
llm plugins                       # your plugin is listed with its hooks
llm models | grep <prefix>        # models registered
llm tools                         # tools registered
llm embed-models list             # embedding models registered
llm -m <model> -T <tool> "..." --td   # tool execution, with debug output
```

### 10.3 Model providers without a real API key

Point the provider at a local mock server. Most ported providers honor an
`<X>_API_BASE` env var (llm-commandcode: `COMMANDCODE_API_BASE`); the model
catalog is usually already cached, so only the `/generate` request needs
mocking. Set a dummy key and assert on the mock's received body:

```sh
<env>/bin/llm -m commandcode/claude-sonnet-5 "hello" \
  # with COMMANDCODE_API_BASE=http://127.0.0.1:PORT and COMMANDCODE_API_KEY=mock-key
```

Assert the logged request body matches the provider's own test fixtures
(messages/tools/system headers). This catches every serialization bug without
spending a real request. Verify the tool-call → tool-result round trip by
having the mock emit a `tool-call` event on the first request and text on the
second.

---

## 11. Conventions & gotchas

- **Never set `mainProgram = null`** in `meta` — newer nixpkgs propagates it
  into the env as `NIX_MAIN_PROGRAM`, and env values can't be null. Omit it.
- **`doCheck = false`** — vendored plugins ship no tests; the sandbox has no
  network.
- **`propagatedBuildInputs`**, not `buildInputs`, for runtime imports.
- **`pythonImportsCheck`** uses the module name (`llm_myplugin`), not the
  project name.
- **`requires-python`** in `pyproject.toml` should roughly match the Nix
  Python; plugins here use `>=3.8`/`>=3.9`.
- **`license`** must match the source; omit rather than guess (see
  `llm-tools-rag`).
- **All changes are declarative** (`users.mutableUsers = false`): nothing is
  installed imperatively. After editing, apply with
  `sudo nixos-rebuild switch --flake .#EVA-02` **only with explicit user
  permission** (see `AGENTS.md`).
- **Prefer vendoring** (`src = ./.;`) over `fetchFromGitHub` when the plugin
  is small or modified; fetch only unmodified third-party code
  (`llm-tools-rag`).
- **External binaries are a runtime concern.** The derivation provides Python
  deps only; `ctx7`, `ripgrep`, `git`, etc. must be in
  `home.packages`/`environment.systemPackages`.
