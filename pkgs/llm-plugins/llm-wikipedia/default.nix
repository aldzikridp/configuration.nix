# llm-wikipedia: slices /pkgs/llm-wikipedia out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-wikipedia";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-wikipedia";

  build-system = [ setuptools ];

  propagatedBuildInputs = [ llm ];

  doCheck = false;

  pythonImportsCheck = [ "llm_wikipedia" ];

  meta = {
    description = "LLM plugin providing a search_wikipedia tool (ported from aichat).";
    homepage = "https://github.com/sigoden/aichat";
    license = lib.licenses.mit;
  };
}
