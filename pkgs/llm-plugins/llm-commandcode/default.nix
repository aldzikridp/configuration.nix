# Nix derivation for the `llm-commandcode` plugin.
#
# This plugin is NOT in nixpkgs — it is vendored into this repo alongside
# this file (llm_commandcode.py, pyproject.toml, README.md).
#
# It is a port of the pi extension https://github.com/patlux/pi-commandcode-provider
# (Command Code provider for https://commandcode.ai).
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into a python env that also contains `llm`, e.g.:
#   myPython.withPackages (ps: [ ps.llm ps.llm-commandcode ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up
# in `llm plugins` / `llm models`. See home/llm.nix for the wiring.
{
  lib,
  buildPythonPackage,
  llm,
  httpx,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-commandcode";
  version = "0.1.0";
  pyproject = true;

  # Vendor the source files that sit next to this default.nix.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (we subclass llm.KeyModel and use
  # @llm.hookimpl), and `httpx` performs the /alpha/generate streaming
  # request and model catalog fetch — both propagated so they land in the
  # python env alongside the plugin. `click` (used by register_commands)
  # comes in transitively with llm.
  propagatedBuildInputs = [
    llm
    httpx
  ];

  # No tests shipped with the plugin.
  doCheck = false;

  pythonImportsCheck = [ "llm_commandcode" ];

  meta = {
    description = "LLM plugin providing Command Code (commandcode.ai) models with streaming, tools, reasoning, and image input.";
    homepage = "https://github.com/patlux/pi-commandcode-provider";
    license = lib.licenses.mit;
    # No `mainProgram` — this is a plugin with no CLI of its own.
    # Setting `mainProgram = null` is forbidden in newer nixpkgs because
    # the build machinery propagates it into env as NIX_MAIN_PROGRAM and
    # env values cannot be null.
  };
}