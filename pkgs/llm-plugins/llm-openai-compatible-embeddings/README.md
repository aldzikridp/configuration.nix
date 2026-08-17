# llm-openai-compatible-embeddings

[LLM](https://llm.datasette.io/) plugin for any OpenAI-compatible `/embeddings`
endpoint (Ollama, LM Studio, vLLM, TEI, Jina, Together, Groq, ...).

## Setup

Create `~/.config/io.datasette.llm/openai-compatible-embeddings.yaml`:

```yaml
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
```

Key sources, in order: `api_key` (literal) → `llm_key` (`llm keys set <name>`)
→ `api_key_env` → none if `no_auth: true` → otherwise an error.
Per-server: `verify_tls` (true), `timeout_seconds` (30), `extra_headers`, `batch_size`.
Per-model: `aliases`, `dimensions`, `batch_size`.

## Usage

```bash
llm embed-models list
llm embed -m ollama/nomic-embed-text -c "hello world"
llm embed -m jina/jina-embeddings-v3 -c mycollection -i doc.txt
```

Each model is registered under `<name>/<model>` plus any configured aliases.