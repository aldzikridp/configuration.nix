# Nix derivation for the `llm-tools-rag` plugin, fetched from GitHub
# (https://github.com/daturkel/llm-tools-rag) — not vendored, not in nixpkgs.
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into a python env that also contains `llm`, e.g.:
#   myPython.withPackages (ps: [ ps.llm ps.llm-tools-rag ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up
# in `llm plugins` / `llm tools`. See home/llm.nix for the wiring.
#
# The plugin registers a single `RAG` Toolbox class exposing the tools
# `RAG_get_collections` and `RAG_get_relevant_documents`, which search
# llm's embeddings database (`llm.user_dir()/embeddings.db` by default).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  llm,
  sqlite-utils,
}:

buildPythonPackage rec {
  pname = "llm-tools-rag";
  version = "0.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "daturkel";
    repo = "llm-tools-rag";
    tag = version;
    hash = "sha256-sFu0Tq7HWg8i4uHyRJP8RKIbhHHge3nAs6Ufv++dE9Y=";
  };

  build-system = [ setuptools ];

  # `llm` is a runtime import (we use `@llm.hookimpl` / `llm.Toolbox`), and
  # `sqlite-utils` is used to query llm's embedding databases — both
  # propagated so they land in the python env alongside the plugin.
  dependencies = [
    llm
    sqlite-utils
  ];

  # Skip the upstream pytest suite (consistent with our other custom plugins).
  doCheck = false;

  pythonImportsCheck = [ "llm_tools_rag" ];

  meta = {
    description = "LLM tool plugin for searching over embedding collections (RAG)";
    homepage = "https://github.com/daturkel/llm-tools-rag";
    changelog = "https://github.com/daturkel/llm-tools-rag/releases/tag/${version}";
    # license intentionally omitted — upstream pyproject says MIT, README badge
    # says Apache 2.0, and there is no LICENSE file. Leave it unspecified.
  };
}
