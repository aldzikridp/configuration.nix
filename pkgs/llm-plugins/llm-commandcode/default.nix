# Nix derivation for the `llm-commandcode` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources (.py/.toml/README) remain on disk until T7; src now
# slices into the fetched tree. See llm-plugins/README.md and PLAN.md:§2.2.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  httpx,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-commandcode";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    rev = "v0.1.0";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-commandcode";

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    llm
    httpx
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_commandcode" ];

  meta = {
    description = "LLM plugin providing Command Code (commandcode.ai) models with streaming, tools, reasoning, and image input.";
    homepage = "https://github.com/patlux/pi-commandcode-provider";
    license = lib.licenses.mit;
  };
}
