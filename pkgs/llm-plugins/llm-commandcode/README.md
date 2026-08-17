# llm-commandcode

An [llm](https://llm.datasette.io/) plugin that provides
[Command Code](https://commandcode.ai) models.
## What it provides

- Models are discovered dynamically from the Command Code Provider API
  (`https://api.commandcode.ai/provider/v1/models`) and registered as
  `commandcode/{id}`, e.g. `commandcode/deepseek/deepseek-v4-flash`.
- Streaming text, tool calling, reasoning/thinking blocks, and image input
  for vision-capable models.
- The model catalog is cached at `~/.config/io.datasette.llm/commandcode-models.json`
  (24 hour TTL) so `llm` stays fast; `llm commandcode-models --refresh`
  forces a live refresh.
- Per-model `-o reasoning_effort` mapped through the Command Code CLI's
  effort catalog (unknown/unsupported values are omitted rather than sent).

## Install

With Home Manager (this repo):

```nix
# home/llm.nix
llm-commandcode = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-commandcode/default.nix { };
```

Or with pip:

```sh
llm install llm-commandcode
```

## Authentication

llm resolves the key in this order:

1. `llm keys set commandcode` (preferred)
2. The `COMMANDCODE_API_KEY` environment variable
3. Existing credential files:
   - `~/.commandcode/auth.json`
   - `~/.pi/agent/auth.json`
   - `~/.omp/agent/auth.json`

Supported file shapes:

```json
{ "apiKey": "user_..." }
```

```json
{ "commandcode": "user_..." }
```

```json
{
  "command-code": { "type": "api", "key": "user_..." }
}
```

The Command Code CLI also ships with `commandcode login` — or grab an API
key from the Command Code Studio dashboard and store it with
`llm keys set commandcode`.

## Usage

List available models:

```sh
llm models | grep commandcode
```

Chat:

```sh
llm -m commandcode/deepseek/deepseek-v4-flash "hello"
```

With a system prompt and reasoning effort:

```sh
llm -m commandcode/claude-sonnet-5 -s "You are a terse assistant" \
    -o reasoning_effort max "explain HTTP/3"
```

With tools (needs a tool-enabled llm, e.g. the ones wired up via
`llm-tools-*` plugins in this repo):

```sh
llm -m commandcode/deepseek/deepseek-v4-flash -t ctx7_search \
    "check the llm docs" --td
```

With an image (text-only models reject the image before any request):

```sh
llm -m commandcode/gpt-5.6-luna -a screenshot.png "what is this?"
```

Override the default output token budget:

```sh
llm -m commandcode/deepseek/deepseek-v4-pro -o max_tokens 8000 "story"
```

Diagnostics:

```sh
llm commandcode-models          # status + model list
llm commandcode-models --refresh   # force live catalog refresh
llm commandcode-models --json     # machine-readable
```

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `COMMANDCODE_API_KEY` | — | API key (alternative to `llm keys set commandcode`) |
| `COMMANDCODE_API_BASE` | `https://api.commandcode.ai` | API base URL (test mocks / compatible endpoints) |
| `COMMANDCODE_MODELS_URL` | `<base>/provider/v1/models` | Model catalog URL |
| `COMMANDCODE_MODELS_CACHE` | `<llm user dir>/commandcode-models.json` | Catalog cache path |
| `COMMANDCODE_MODELS_TIMEOUT_MS` | `10000` | Catalog fetch timeout |
| `COMMANDCODE_AUTH_FILES` | — | `:`-separated list of additional auth.json files to read |

## Notes / scope

- Browser OAuth (`/login`) is not ported — llm has no login UI; store the
  key with `llm keys set commandcode`.
- Prior thinking/reasoning blocks are shown in session output but are never
  replayed to Command Code in follow-up requests (matches the pi extension
  and the Command Code CLI).
- Per-request cost display is not ported (llm has no dollar-cost UI).
