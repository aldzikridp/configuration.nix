# Replacement for home/llm.nix
#
# Wires the five custom plugins (llm-ctx7, llm-wikipedia, llm-fetch-url,
# llm-file-tools, llm-openrouter-embeddings) into the `llm` CLI alongside
# the existing nixpkgs-bundled plugins.
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
#    We need to inject our five custom plugin derivations into a Python
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
{ pkgs, ... }:

let
  # Step 1: Extend `pkgs` with a Python packages extension that disables
  # tests on `courlan` and `trafilatura`. The extension is applied to
  # every Python interpreter's package set, so when `trafilatura`'s
  # callPackage resolves `courlan`, it gets the test-disabled version —
  # producing a different .drv hash and a working build.
  #
  # The library works fine at runtime; only the test suites are broken
  # on Python 3.13. Track upstream: https://github.com/adbar/courlan/issues
  pkgs' = pkgs.extend (final: prev: {
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
    ];
  });

  # Step 2: Build the three plugin derivations using the EXTENDED pkgs.
  # Because the extension applies to python3Packages too, `trafilatura`
  # (pulled in by llm-fetch-url/default.nix) resolves to the test-disabled
  # version, and so does its transitive `courlan` dep.
  llm-ctx7-pkg       = pkgs'.python3Packages.callPackage ../pkgs/llm-ctx7/default.nix { };
  llm-wikipedia-pkg  = pkgs'.python3Packages.callPackage ../pkgs/llm-wikipedia/default.nix { };
  llm-fetch-url-pkg  = pkgs'.python3Packages.callPackage ../pkgs/llm-fetch-url/default.nix { };

  # llm-file-tools plugin: read_file / write_file / patch_file / apply_diff /
  # list_dir / grep_file (ripgrep+grep) / git_apply. Runtime deps on PATH:
  # `git` (already in environment.systemPackages) and `ripgrep` (added to
  # configuration.nix) — without ripgrep, grep_file falls back to grep.
  llm-file-tools-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-file-tools/default.nix { };

  # llm-openrouter-embeddings plugin: embedding models hosted by OpenRouter
  # (https://openrouter.ai/api/v1). The model list is user-provided at
  # runtime via ~/.config/io.datasette.llm/openrouter-embeddings.yaml —
  # see pkgs/llm-openrouter-embeddings/README.md.
  llm-openrouter-embeddings-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-openrouter-embeddings/default.nix { };

  # llm-tools-rag plugin: RAG tool (get_collections / get_relevant_documents)
  # for searching llm's embeddings database. Fetched from GitHub via
  # fetchFromGitHub (see pkgs/llm-tools-rag/default.nix).
  llm-tools-rag-pkg = pkgs'.python3Packages.callPackage ../pkgs/llm-tools-rag/default.nix { };

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
    };
  };

  # Step 4: Build ONE python environment that contains `llm`, the
  # nixpkgs-bundled plugins we want, AND the three custom plugins. `ps`
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

