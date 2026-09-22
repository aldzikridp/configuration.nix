# llm-openai-compatible-embeddings: slices /pkgs/llm-openai-compatible-embeddings out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  httpx,
  pyyaml,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-openai-compatible-embeddings";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-openai-compatible-embeddings";

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    llm
    httpx
    pyyaml
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_openai_compatible_embeddings" ];

  meta = {
    description = "LLM plugin for OpenAI-compatible HTTP embedding APIs.";
    homepage = "https://github.com/simonw/llm";
    license = lib.licenses.mit;
  };
}
