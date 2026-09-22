# llm-openrouter-embeddings: slices /pkgs/llm-openrouter-embeddings out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
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

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-openrouter-embeddings";

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
