# Nix derivation for the `llm-openai-compatible-embeddings` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2.
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-openai-compatible-embeddings";

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
