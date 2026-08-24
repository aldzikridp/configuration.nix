{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  mcp,
  llm,
}:

buildPythonPackage rec {
  pname = "llm-tools-mcp";
  version = "0.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Virtuslab";
    repo = "llm-tools-mcp";
    tag = version;
    hash = "sha256-/cbH90HATUlopqE53ZUHYNtFyn5HSh3xgLtbzwKPFg8=";
  };

  build-system = [ setuptools ];

  dependencies = [
    llm
    mcp
  ];

  doCheck = false;

  pythonImportsCheck = [ "llm_tools_mcp.register_tools" ];

  meta = {
    description = "Connect to MCP servers right from your shell. Plugin for simonw/llm.";
    homepage = "https://github.com/Virtuslab/llm-tools-mcp";
    changelog = "https://github.com/Virtuslab/llm-tools-mcp/releases/tag/${version}";
  };
}
