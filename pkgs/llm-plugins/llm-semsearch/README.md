# llm-semsearch

LLM plugin providing the `semantic_search` tool for semantic search over
local documents indexed by [pg-semantic-search](https://github.com/aldzikridp/semantic-search).

Uses semsearch's Python library directly — no subprocess overhead.

## Setup

1. Ensure semsearch is configured (database, embedding provider via `.env`)
2. Create the config file (optional):

```yaml
# Linux:  ~/.config/io.datasette.llm/semantic-search.yaml
# macOS:  ~/Library/Application Support/io.datasette.llm/semantic-search.yaml

k: 10              # default number of results
rerank: true       # enable reranking by default
filter:            # default filter (optional)
  doc_type: pdf
config: /path/to/.env  # path to semsearch .env (optional)
```

3. Use:

```bash
llm -T semantic_search "how to configure the database" --td
```

## Config Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `k` | int | 5 | Number of results to return |
| `rerank` | bool | false | Use configured reranker |
| `filter` | dict | none | Default PGVectorStore filter |
| `config` | string | none | Path to semsearch .env file |

All settings are optional. CLI args override config defaults.

## Tool Args

| Arg | Type | Description |
|-----|------|-------------|
| `query` | str | The search query (required) |
| `k` | int | Override number of results |
| `filter` | str | JSON filter string, e.g. `'{"doc_type": "pdf"}'` |
| `rerank` | bool | Override reranking |

## Output Format

Results are formatted as readable text:

```
[1] /path/to/file.pdf (score: 0.892)
<chunk content>

[2] /path/to/other.md (score: 0.847)
<chunk content>
```
