# Nix derivation for the `llm-openrouter-embeddings` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  openai,
  pyyaml,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-openrouter-embeddings";
  version = "0.2.0";
  pyproject = true;

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    rev = "v0.1.0";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-openrouter-embeddings";

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    llm
    openai
    pyyaml
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_openrouter_embeddings" ];

  meta = {
    description = "Config-driven LLM plugin for OpenRouter embedding models.";
    homepage = "https://openrouter.ai/";
    license = lib.licenses.mit;
  };
}
