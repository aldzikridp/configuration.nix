# llm-semantic-search: slices /pkgs/llm-semantic-search out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  llm,
  pyyaml,
  httpx2,
}:

buildPythonPackage rec {
  pname = "llm-semantic-search";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-semantic-search";

  build-system = [ setuptools ];

  propagatedBuildInputs = [ llm pyyaml httpx2 ];

  doCheck = false;

  pythonImportsCheck = [ "llm_semantic_search" ];

  meta = {
    description = "LLM plugin providing semantic search via semsearch HTTP server";
    homepage = "https://github.com/aldzikridp/semantic-search";
    license = lib.licenses.mit;
  };
}
