# llm-fetch-url: slices /pkgs/llm-fetch-url out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  trafilatura,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-fetch-url";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-fetch-url";

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    llm
    trafilatura
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_fetch_url" ];

  meta = {
    description = "LLM plugin providing a fetch_url tool (ported from aichat).";
    homepage = "https://github.com/sigoden/aichat";
    license = lib.licenses.mit;
  };
}
