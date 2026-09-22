# llm-plugins — fetch wrappers

Sources live in the private repo
[`github:aldzikridp/llm-plugins`](https://github.com/aldzikridp/llm-plugins),
pinned **once** in `source.nix` (`rev` + `hash`). Every `default.nix` in
this directory fetches it itself and slices to `"/pkgs/<name>"`:

```nix
src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-ctx7";
```

Nix deduplicates the identical fixed-output fetch, so the repo is built
once regardless of how many wrappers import `source.nix`. Keeping the
rev/hash in that one file is what stops the wrappers from drifting out of
sync — they used to repeat it inline, and the 6 wrappers that are
currently disabled in `home/llm.nix` (wikipedia, fetch-url, file-tools,
both *-embeddings, semsearch) had drifted to the current rev with the
*v0.1.0* tree hash, so they could not build if re-enabled. Only the 3
enabled ones (ctx7, commandcode, semantic-search) had the right hash.

- No flake input and no `home/llm.nix` change. Each wrapper is
  self-contained: `callPackage ../pkgs/llm-plugins/<name>/default.nix
  { }` works from any call site with no extra args (the
  `llm-tools-rag` wrapper resolves its own `fetchFromGitHub` the same
  way).
- `llm-fetch-curl` was dropped (orphaned duplicate `pname`, unused in
  `home/llm.nix` — see `PLAN.md:§1.1` / `TODO.md:T1`).
- 9 vendored wrappers (`llm-commandcode`, `llm-ctx7`, `llm-fetch-url`,
  `llm-file-tools`, `llm-openai-compatible-embeddings`,
  `llm-openrouter-embeddings`, `llm-semantic-search`, `llm-semsearch`,
  `llm-wikipedia`) share one source; Nix deduplicates the fetch. 3
  upstream wrappers (`llm-tools-exa`, `llm-tools-mcp`, `llm-tools-rag`)
  fetch from `daturkel`/`Virtuslab` and are self-contained.
- Bumps: edit `rev` in `source.nix`, then
  `nix flake prefetch github:aldzikridp/llm-plugins/<rev> --json` and
  replace `hash` with the `narHash` it prints. Bump a wrapper's
  `version` only if that plugin's `pyproject.toml` version changed (it is
  not used to fetch anything).

The former vendored files (`llm_*.py`, `pyproject.toml`, per-plugin
`README.md`) now live only in `llm-plugins/pkgs/<name>/`; `configuration.nix`
now contains only `default.nix` per plugin.

Former guide (21.9KB) archived at the split commit; canonical copy is
`llm-plugins/README.md`.
