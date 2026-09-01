# llm-plugins — fetch wrappers

Sources moved to [`github:aldzikridp/llm-plugins`](https://github.com/aldzikridp/llm-plugins)
(tag `v0.1.0`, commit `e3b8870359b52b375d9b844bcb561095b37e284b`). Each
`default.nix` in this directory fetches its source via `fetchFromGitHub`
(**Pattern A — per-`default.nix`**, `rev = "v0.1.0"`,
`hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY="`) and
slices to `"/pkgs/<name>"`. See `../../llm-plugins/README.md` and
`../../llm-plugins/PLAN.md:§2.2` for the inventory, writing guide, and
fetch details.

- `flake.nix` / `flake.lock` / `home/llm.nix` are unchanged (no flake
  input) — `callPackage ../pkgs/llm-plugins/<name>/default.nix` still
  works; only `default.nix` internals switched from `src = ./.;` to
  `fetchFromGitHub`.
- `llm-fetch-curl` was dropped (orphaned duplicate `pname`, unused in
  `home/llm.nix` — see `PLAN.md:§1.1` / `TODO.md:T1`).
- 9 vendored wrappers (`llm-commandcode`, `llm-ctx7`, `llm-fetch-url`,
  `llm-file-tools`, `llm-openai-compatible-embeddings`,
  `llm-openrouter-embeddings`, `llm-semantic-search`, `llm-semsearch`,
  `llm-wikipedia`) share the same `owner/repo/rev/hash`; Nix deduplicates
  the fetch. 3 upstream wrappers (`llm-tools-exa`, `llm-tools-mcp`,
  `llm-tools-rag`) still fetch from `daturkel`/`Virtuslab`.
- Bumps: push + tag `v0.2.0` in `llm-plugins`, re-run
  `nix flake prefetch github:aldzikridp/llm-plugins/v0.2.0 --json`, update
  `rev`/`hash`/`version` in 9 wrappers.

The former vendored files (`llm_*.py`, `pyproject.toml`, per-plugin
`README.md`) now live only in `llm-plugins/pkgs/<name>/`; `configuration.nix`
now contains only `default.nix` per plugin.

Former guide (21.9KB) archived at the split commit; canonical copy is
`llm-plugins/README.md`.
