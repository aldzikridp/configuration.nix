# Wires the custom plugins (llm-ctx7, llm-wikipedia, llm-fetch-url,
# llm-file-tools, llm-openrouter-embeddings, llm-tools-rag, llm-commandcode,
# llm-openai-compatible-embeddings) into the `llm`
# CLI alongside the existing nixpkgs-bundled plugins.
#
# ──────────────────────────────────────────────────────────────────────────
# Key design decisions (read if you're debugging a build failure):
#
# 1. Why `pythonPackagesExtensions` and NOT `python3.override { packageOverrides }`?
#
#    `trafilatura` depends on `courlan`, and `courlan 1.3.2`'s test suite
#    is broken on Python 3.13 (urllib.robotparser no longer initializes
#    `groups` until `parse()` is called). The library itself works fine
#    at runtime; only tests fail.
#
#    The naive fix is:
#      myPython = pkgs.python3.override {
#        packageOverrides = self: super: {
#          courlan = super.courlan.overridePythonAttrs (o: { doCheck = false; });
#        };
#      };
#
#    THIS DOES NOT WORK. `trafilatura`'s .drv was built against the
#    ORIGINAL `pkgs.python3Packages.courlan`, and `overridePythonAttrs`
#    on `courlan` doesn't reach into `trafilatura`'s already-baked-in
#    dependency references. The original broken `courlan` still gets
#    built, and the build still fails with the same .drv hash.
#
#    The correct fix is `pythonPackagesExtensions` — a list of overrides
#    that nixpkgs applies to EVERY Python interpreter's package set
#    (python3, python311, python312, python313, pypy, ...). Because
#    `trafilatura`'s `callPackage` resolves `courlan` THROUGH this
#    extension, the resulting .drv genuinely depends on the test-disabled
#    `courlan`, producing a different hash and a working build.
#
# 2. Why `pkgs.extend` inside `home/llm.nix` instead of `nixpkgs.overlays`?
#
#    The user's `flake.nix` already has `nixpkgs.overlays = [ overlay-unstable ]`.
#    Adding another overlay there would work, but it would force the
#    override to apply system-wide (every Python package on the system
#    would see the modified courlan). Localizing the override to
#    `home/llm.nix` via `pkgs.extend` keeps the blast radius small —
#    only the `llm` tool sees the test-disabled courlan. Everything
#    else on the system still uses the original.
#
# 3. Why we still need `myPython = pkgs'.python3.override { packageOverrides }`:
#
#    We need to inject our six custom plugin derivations into a Python
#    package set BY NAME, so that `myPython.withPackages (ps: [ ps.llm-ctx7 ... ])`
#    can resolve them. `pythonPackagesExtensions` could do this too, but
#    since the custom plugins don't have transitive-dependency issues
#    (they're built fresh from our source), the simpler `packageOverrides`
#    is fine for them.
#
# 4. Why we can't use `llm.withPlugins { ... }` for custom plugins:
#
#    `llm.withPlugins` closes over the `python` that `llm` was originally
#    built against, not the python from whatever package set you call
#    `.withPlugins` on. The overlay adds our plugins to `myPython.pkgs`,
#    but it does NOT rebuild `llm`, so `myPython.pkgs.llm` is literally
#    the same store path as `pkgs.llm`. Its `withPlugins` closure still
#    points at the original `python3`, whose package set has no
#    `llm-ctx7` / etc. — `intersectAttrs setArgs ps` silently drops them.
#
#    Fix: skip `withPlugins` and assemble the env directly with
#    `myPython.withPackages`. `llm` discovers plugins via
#    `importlib.metadata`, so any package in the env whose
#    `pyproject.toml` declares `[project.entry-points.llm]` is picked up
#    automatically.
#
# 5. Why the llm env is based on `pkgs.unstable` and `llm` is overridden to 0.32:
#
#    Neither nixos-26.05 (pinned in flake.nix) nor nixpkgs-unstable ship
#    llm 0.32 yet (stable has 0.30, unstable has 0.31.1). llm 0.32 requires
#    `sqlite-utils>=4.0` and `condense-json>=1.1`. nixpkgs-unstable already
#    has sqlite-utils 4.1.1 (and a coordinated openai/click set), but still
#    has condense-json 0.1.3 — so we base the llm environment on
#    `pkgs.unstable` and add two lightweight overrides via
#    `pythonPackagesExtensions`: `llm` -> 0.32 and `condense-json` -> 1.1.
#    Because this is an EXTENSION (not packageOverrides), every plugin in
#    the env — bundled (llm-gemini, ...) and custom — genuinely rebuilds
#    against llm 0.32, avoiding a dual-llm-version conflict.
#
#    Trade-offs: we drop nixpkgs' install/uninstall-disable patch and the
#    @listOfPackagedPlugins@ postPatch substitution (the other bundled
#    patches target 0.31.1-specific code and may not apply to 0.32), so
#    `llm install`/`uninstall` run real pip — unused here since plugins
#    are managed via Nix. Upstream tests are skipped (doCheck = false),
#    consistent with the vendored plugins.
{ pkgs, ... }:

let
  # Step 1: Extend `pkgs.unstable` (see header section 5 for why unstable)
  # with Python package extensions that (a) disable tests on `courlan` and
  # `trafilatura` and (b) bump `llm` to 0.32 and `condense-json` to 1.1.
  # The extension is applied to every Python interpreter's package set, so
  # when `trafilatura`'s callPackage resolves `courlan`, it gets the
  # test-disabled version — producing a different .drv hash and a working
  # build. The library works fine at runtime; only the test suites are
  # broken on Python 3.13.
  # Track upstream: https://github.com/adbar/courlan/issues
  pkgs' = pkgs.unstable.extend (final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (python-final: python-prev: {
        # Issue: https://github.com/NixOS/nixpkgs/issues/551795
        courlan = python-prev.courlan.overridePythonAttrs (old: {
          doCheck = false;
        });
        trafilatura = python-prev.trafilatura.overridePythonAttrs (old: {
          doCheck = false;
        });
      })

      # llm 0.32 + condense-json 1.1 (llm 0.32 requires condense-json>=1.1).
      # `final` here is the top-level `pkgs.unstable`, which provides
      # fetchFromGitHub. sqlite-utils 4.1.1 already comes from unstable.
      (python-final: python-prev: {
        condense-json = python-prev.condense-json.overridePythonAttrs (old: {
          version = "1.1";
          src = final.fetchFromGitHub {
            owner = "simonw";
            repo = "condense-json";
            tag = "1.1";
            hash = "sha256-IBYjDFhbQlZ/17nTo5FvJM7aeadKS5dW7J8IGy4956M=";
          };
          # 1.1's test suite needs `hypothesis`, which the 0.1.3
          # derivation doesn't provide; skip tests (library works fine).
          doCheck = false;
        });
        llm = python-prev.llm.overridePythonAttrs (old: {
          version = "0.32";
          src = final.fetchFromGitHub {
            owner = "simonw";
            repo = "llm";
            tag = "0.32";
            hash = "sha256-lDPF4Z+U9Zlqc1Dt7pCrxmthAZj4a0hNpz5d8J7TtM8=";
          };
          # Drop nixpkgs' install/uninstall-disable patch and the
          # @listOfPackagedPlugins@ postPatch substitution (the other
          # bundled patches target 0.31.1-specific code and may not apply
          # to 0.32). Plugins are managed via Nix, so `llm install` is
          # unused.
          patches = [];
          postPatch = "";
          doCheck = false;
        });
      })
    ];
  });

  # Step 2: Build the plugins derivations using the EXTENDED pkgs.
  # Because the extension applies to python3Packages too, `trafilatura`
  # (pulled in by llm-plugins/llm-fetch-url/default.nix) resolves to the test-disabled
  # version, and so does its transitive `courlan` dep.
  llm-ctx7-pkg       = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-ctx7/default.nix { };
  llm-wikipedia-pkg  = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-wikipedia/default.nix { };
  llm-fetch-url-pkg  = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-fetch-url/default.nix { };

  # llm-file-tools plugin: read_file / write_file / patch_file / apply_diff /
  # list_dir / grep_file (ripgrep+grep) / git_apply. Runtime deps on PATH:
  # `git` (already in environment.systemPackages) and `ripgrep` (added to
  # configuration.nix) — without ripgrep, grep_file falls back to grep.
  llm-file-tools-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-file-tools/default.nix { };

  # llm-openrouter-embeddings plugin: embedding models hosted by OpenRouter
  # (https://openrouter.ai/api/v1). The model list is user-provided at
  # runtime via ~/.config/io.datasette.llm/openrouter-embeddings.yaml —
  # see pkgs/llm-plugins/llm-openrouter-embeddings/README.md.
  llm-openrouter-embeddings-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-openrouter-embeddings/default.nix { };

  # llm-tools-rag plugin: RAG tool (get_collections / get_relevant_documents)
  # for searching llm's embeddings database. Fetched from GitHub via
  # fetchFromGitHub (see pkgs/llm-plugins/llm-tools-rag/default.nix).
  llm-tools-rag-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-tools-rag/default.nix { };

  # llm-commandcode plugin: Command Code (commandcode.ai) model provider,
  # ported from the pi extension pi-commandcode-provider. Models are
  # discovered from the Provider API at runtime (commandcode/{id}), with
  # streaming, tools, reasoning, and image input. Uses `llm keys set
  # commandcode` / COMMANDCODE_API_KEY, falling back to existing pi/commandcode
  # auth.json files. See pkgs/llm-plugins/llm-commandcode/README.md.
  llm-commandcode-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-commandcode/default.nix { };

  # llm-openai-compatible-embeddings plugin: embedding models against any
  # OpenAI-compatible /embeddings endpoint (Ollama, LM Studio, vLLM, Jina,
  # ...). Servers/models are user-configured at runtime via
  # ~/.config/io.datasette.llm/openai-compatible-embeddings.yaml — see
  # pkgs/llm-plugins/llm-openai-compatible-embeddings/README.md.
  llm-openai-compatible-embeddings-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-openai-compatible-embeddings/default.nix { };

  # llm-semsearch plugin: semantic_search tool backed by semsearch's Python
  # library (SemanticSearchService). Reads search defaults from
  # <llm.user_dir()>/semantic-search.yaml. semsearch is built against pkgs'
  # so it's ABI-compatible with the llm env.
  semsearch-pkg       = pkgs'.python3Packages.callPackage ../pkgs/semsearch/default.nix { };
  llm-semsearch-pkg   = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-semsearch/default.nix {
    pg-semantic-search = semsearch-pkg;
  };

  # llm-semantic-search plugin: semantic_search tool via HTTP API.
  # Sends requests to a running semsearch serve endpoint instead of calling
  # the Python library directly. Reads config from
  # <llm.user_dir()>/semantic-search-server.yaml.
  llm-semantic-search-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-plugins/llm-semantic-search/default.nix { };

  # Step 3: Override python3 to add our custom plugins by name. We need
  # this so that `myPython.withPackages (ps: [ ps.llm-ctx7 ... ])` below
  # can resolve them — `withPackages` pulls from the overridden package
  # set. We use the EXTENDED pkgs' here so any python package lookups
  # during plugin resolution also go through the extension.
  myPython = pkgs'.python3.override {
    packageOverrides = self: super: {
      llm-ctx7       = llm-ctx7-pkg;
      llm-wikipedia  = llm-wikipedia-pkg;
      llm-fetch-url  = llm-fetch-url-pkg;
      llm-file-tools = llm-file-tools-pkg;
      llm-openrouter-embeddings = llm-openrouter-embeddings-pkg;
      llm-tools-rag = llm-tools-rag-pkg;
      llm-commandcode = llm-commandcode-pkg;
      llm-openai-compatible-embeddings = llm-openai-compatible-embeddings-pkg;
      pg-semantic-search = semsearch-pkg;
      llm-semsearch = llm-semsearch-pkg;
      llm-semantic-search = llm-semantic-search-pkg;
    };
  };

  # Step 4: Build ONE python environment that contains `llm`, the
  # nixpkgs-bundled plugins we want, AND the custom plugins. `ps`
  # here is `myPython.pkgs`, so `ps.llm-ctx7` / etc. resolve via the
  # Step 3 overlay.
  myLlmEnv = myPython.withPackages (ps: with ps; [
    llm
    # --- existing nixpkgs-bundled plugins (preserved from old home/llm.nix) ---
    llm-gemini
    llm-jq
    llm-cmd
    llm-git
    llm-docs
    # --- custom plugins (vendored in this repo) ---
    llm-ctx7
    llm-wikipedia
    llm-fetch-url
    llm-file-tools
    llm-openrouter-embeddings
    llm-tools-rag
    llm-commandcode
    #llm-openai-compatible-embeddings
    #llm-semsearch
    llm-semantic-search
  ]);

  # Step 5: `myLlmEnv` is a full python environment; we only want the
  # `llm` binary on PATH, so symlink it out into a thin wrapper. This
  # mirrors exactly what `llm.withPlugins` does internally.
  myLlm = pkgs'.runCommand "llm-with-custom-plugins" { } ''
    mkdir -p $out/bin
    ln -s ${myLlmEnv}/bin/llm $out/bin/llm
  '';
in
{
  home.packages = [ myLlm ];
}

