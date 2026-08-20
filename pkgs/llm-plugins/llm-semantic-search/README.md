# llm-semantic-search

LLM plugin providing semantic search via a running `semsearch serve` HTTP endpoint.

Unlike `llm-semsearch` (which calls the Python library directly), this plugin sends HTTP requests to a remote or shared server.

## Setup

1. Start the semsearch server:
   ```bash
   semsearch serve --host 0.0.0.0 --port 8383
   ```

2. Create the config file at `~/.config/io.datasette.llm/semantic-search-server.yaml`:
   ```yaml
   host: localhost
   port: 8383
   k: 10
   rerank: true
   ```

## Usage

```bash
# Basic search
llm -T semantic_search "how to configure the system"

# With filter
llm -T semantic_search "deploy instructions" --tool-option semantic_search.filter='{"doc_type": "pdf"}'
```

## Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `host` | string | `localhost` | Server hostname |
| `port` | int | `8383` | Server port |
| `k` | int | `5` | Number of results |
| `rerank` | bool | `false` | Enable reranking |
| `filter` | dict | `null` | Default filter |

## Filter Syntax

- Specific file: `{"source": "path/to/file.md"}`
- File type: `{"doc_type": "pdf"}`
- Directory prefix: `{"source": {"$ilike": "docs/%"}}`
- Multiple types: `{"doc_type": {"$in": ["pdf", "csv"]}}`
- Combine AND: `{"$and": [{...}, {...}]}`
- Combine OR: `{"$or": [{...}, {...}]}`
