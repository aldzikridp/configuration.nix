# llm-semsearch: slices /pkgs/llm-semsearch out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  llm,
  pyyaml,
  pg-semantic-search,
}:

buildPythonPackage rec {
  pname = "llm-semsearch";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-semsearch";

  build-system = [ setuptools ];

  propagatedBuildInputs = [ llm pyyaml pg-semantic-search ];

  doCheck = false;

  pythonImportsCheck = [ "llm_semsearch" ];

  meta = {
    description = "LLM plugin providing semantic search over local documents via semsearch";
    homepage = "https://github.com/aldzikridp/semantic-search";
    license = lib.licenses.mit;
  };
}
