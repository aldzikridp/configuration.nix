# Nix derivation for the `llm-fetch-url` plugin.
#
# This plugin is NOT in nixpkgs — it is vendored into this repo alongside
# this file (llm_fetch_url.py, pyproject.toml, README.md).
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into a python env that also contains `llm`, e.g.:
#   myPython.withPackages (ps: [ ps.llm ps.llm-fetch-url ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up
# in `llm plugins` / `llm tools`. See home/llm.nix for the full wiring.
#
# Note: this derivation only builds the Python plugin. The runtime
# dependencies (curl, pandoc, sed) must be on the user's PATH at use
# time — typically added to `home.packages` separately, alongside this
# plugin.
{
  lib,
  buildPythonPackage,
  llm,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-fetch-url";
  version = "0.1.0";
  pyproject = true;

  # Vendor the source files that sit next to this default.nix.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (we use `@llm.hookimpl`), so it must be
  # propagated.
  propagatedBuildInputs = [ llm ];

  # No tests shipped with the plugin.
  doCheck = false;

  pythonImportsCheck = [ "llm_fetch_url" ];

  meta = {
    description = "LLM plugin providing a fetch_url tool (ported from aichat).";
    homepage = "https://github.com/sigoden/aichat";
    license = lib.licenses.mit;
    # No `mainProgram` — this is a plugin with no CLI of its own.
    # Setting `mainProgram = null` is forbidden in newer nixpkgs because
    # the build machinery propagates it into env as NIX_MAIN_PROGRAM and
    # env values cannot be null.
  };
}
