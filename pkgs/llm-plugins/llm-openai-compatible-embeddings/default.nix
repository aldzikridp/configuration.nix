# Nix derivation for the `llm-openai-compatible-embeddings` plugin.
#
# Vendored into this repo (not in nixpkgs). Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Inject it into a python env that also contains `llm`:
#   myPython.withPackages (ps: [ ps.llm ps.llm-openai-compatible-embeddings ])
# `llm` discovers plugins via importlib.metadata, so the entry point in
# pyproject.toml ([project.entry-points.llm]) is what makes it show up in
# `llm plugins` / `llm embed-models`. See home/llm.nix for the wiring.
#
# Servers/models are user-configured at runtime via
# ~/.config/io.datasette.llm/openai-compatible-embeddings.yaml — nothing is
# baked into this derivation.
{
  lib,
  buildPythonPackage,
  llm,
  httpx,
  pyyaml,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-openai-compatible-embeddings";
  version = "0.1.0";
  pyproject = true;

  # Vendor the source files that sit next to this default.nix.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (@llm.hookimpl). `httpx` makes the HTTP
  # requests; `pyyaml` parses the user's config file. All propagated so
  # they land in the python env alongside the plugin.
  propagatedBuildInputs = [
    llm
    httpx
    pyyaml
  ];

  # No tests shipped with the plugin.
  doCheck = false;

  pythonImportsCheck = [ "llm_openai_compatible_embeddings" ];

  meta = {
    description = "LLM plugin for OpenAI-compatible HTTP embedding APIs.";
    homepage = "https://github.com/simonw/llm";
    license = lib.licenses.mit;
    # No `mainProgram` — never set it to null (see llm-plugins/README.md).
  };
}