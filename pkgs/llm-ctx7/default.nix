# Nix derivation for the `llm-ctx7` plugin.
#
# This plugin is NOT in nixpkgs — it is vendored into this repo alongside
# this file (llm_ctx7.py, pyproject.toml, README.md).
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into a python env that also contains `llm`, e.g.:
#   myPython.withPackages (ps: [ ps.llm ps.llm-ctx7 ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up
# in `llm plugins` / `llm tools`. See home/llm.nix for the full wiring.
{
  lib,
  buildPythonPackage,
  llm,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-ctx7";
  version = "0.1.0";
  pyproject = true;

  # Vendor the source files that sit next to this default.nix.
  # buildPythonPackage only needs pyproject.toml + the module file; the
  # extra files (this default.nix, README.md) are simply ignored.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (we use `@llm.hookimpl`), so it must be
  # propagated — that way any Python env that pulls in `llm-ctx7` also
  # gets `llm`. Inside `llm.withPlugins { ... }` this is harmless
  # because `llm` is already in the env.
  propagatedBuildInputs = [ llm ];

  # No tests shipped with the plugin.
  doCheck = false;

  pythonImportsCheck = [ "llm_ctx7" ];

  meta = {
    description = "LLM plugin providing a ctx7_search tool (ported from aichat).";
    homepage = "https://github.com/sigoden/aichat";
    license = lib.licenses.mit;
    # No `mainProgram` — this is a plugin with no CLI of its own.
    # Setting `mainProgram = null` is forbidden in newer nixpkgs because
    # the build machinery propagates it into env as NIX_MAIN_PROGRAM and
    # env values cannot be null.
  };
}
