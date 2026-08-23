{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  llm,
  exa-py,
}:

buildPythonPackage rec {
  pname = "llm-tools-exa";
  version = "0.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "daturkel";
    repo = "llm-tools-exa";
    tag = version;
    hash = "sha256-LOG9j0LtUw4ZYXFLnsiIChXI4j4hHA7WjXGqNLCwew0=";
  };

  build-system = [ setuptools ];

  dependencies = [
    llm
    exa-py
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_tools_exa" ];

  meta = {
    description = "A tool plugin for LLM that allows you to search the web using Exa.";
    homepage = "https://github.com/daturkel/llm-tools-exa";
    changelog = "https://github.com/daturkel/llm-tools-exa/releases/tag/${version}";
  };
}
