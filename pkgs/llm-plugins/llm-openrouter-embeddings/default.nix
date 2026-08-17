# Nix derivation for the `llm-openrouter-embeddings` plugin.
#
# This plugin is NOT in nixpkgs — it is vendored into this repo alongside
# this file (llm_openrouter_embeddings.py, pyproject.toml, README.md).
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into a python env that also contains `llm`, e.g.:
#   myPython.withPackages (ps: [ ps.llm ps.llm-openrouter-embeddings ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up
# in `llm plugins` / `llm embed-models`. See home/llm.nix for the wiring.
#
# The model list is NOT baked into this derivation: the user lists the
# OpenRouter model IDs in ~/.config/io.datasette.llm/openrouter-embeddings.yaml.
# Per-model provider routing (order / allow_fallbacks / data_collection) is
# optional and forwarded as {"provider": ...} on the request body.
{
  lib,
  buildPythonPackage,
  llm,
  openai,
  pyyaml,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-openrouter-embeddings";
  version = "0.2.0";
  pyproject = true;

  # Vendor the source files that sit next to this default.nix.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (we use `@llm.hookimpl`), so it must be
  # propagated. `openai` is the OpenAI-compatible client used to call the
  # OpenRouter embeddings endpoint, and `pyyaml` parses the user's config
  # file — both propagated so they land in the python env alongside the
  # plugin.
  propagatedBuildInputs = [
    llm
    openai
    pyyaml
  ];

  # No tests shipped with the plugin.
  doCheck = false;

  pythonImportsCheck = [ "llm_openrouter_embeddings" ];

  meta = {
    description = "Config-driven LLM plugin for OpenRouter embedding models.";
    homepage = "https://openrouter.ai/";
    license = lib.licenses.mit;
    # No `mainProgram` — this is a plugin with no CLI of its own.
    # Setting `mainProgram = null` is forbidden in newer nixpkgs because
    # the build machinery propagates it into env as NIX_MAIN_PROGRAM and
    # env values cannot be null.
  };
}
