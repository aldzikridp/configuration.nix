# llm-commandcode: slices /pkgs/llm-commandcode out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
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

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-commandcode";

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
