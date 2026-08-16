# llm-openrouter-embeddings

[LLM](https://llm.datasette.io/) plugin for [OpenRouter](https://openrouter.ai/)
embedding models. The model list is **not** hard-coded — you provide the
model IDs yourself in a YAML config file.

## Setup

1. Install the plugin (via this NixOS config, see `home/llm.nix`).
2. Store an OpenRouter API key:

   ```bash
   llm keys set openrouter
   ```

   (or set the `OPENROUTER_API_KEY` environment variable instead).

3. Create the config file listing the embedding models you want:

   `~/.config/io.datasette.llm/openrouter-embeddings.yaml`

   ```yaml
   # Simple form: just a model ID.
   - openai/text-embedding-3-small

   # Extended form: optional aliases, dimensions, batch_size.
   - model: voyage/voyage-3
     aliases:
       - openrouter-voyage-3
     batch_size: 50
   - model: openai/text-embedding-3-large
     dimensions: 1024
     batch_size: 25
   ```

   Supported keys per entry:

   | key          | meaning                                                      |
   | ------------ | ------------------------------------------------------------ |
   | `model`      | OpenRouter model ID, e.g. `openai/text-embedding-3-small`    |
   | `aliases`    | extra names you can pass to `llm embed -m`                   |
   | `dimensions` | optional embedding dimension (sent to the API)               |
   | `batch_size` | optional override for how many items to embed per request    |

## Usage

```bash
# List the registered embedding models
llm embed-models list

# Embed a string and print the vector
llm embed -m openrouter/openai/text-embedding-3-small -c "hello world"

# Embed and store in a collection
llm embed -m openrouter/openai/text-embedding-3-small \
  -c mycollection -i mydoc.txt
```

Each model from the config is registered under the id
`openrouter/<model>` (plus any aliases you configured).

## Requirements

- An OpenRouter API key (https://openrouter.ai/keys).
- Your chosen models must support embeddings on OpenRouter.
