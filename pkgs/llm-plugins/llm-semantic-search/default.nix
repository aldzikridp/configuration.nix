# Nix derivation for the `llm-semantic-search` plugin.
#
# Provides the `semantic_search` tool for llm, backed by a running
# semsearch HTTP server (`semsearch serve`). Reads search defaults from
# <llm.user_dir()>/semantic-search-server.yaml.
#
# Unlike llm-semsearch (which calls the Python library directly), this
# plugin sends HTTP requests to a remote or shared server.
#
# Build via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into the llm python env (see home/llm.nix).
{
  lib,
  buildPythonPackage,
  setuptools,
  llm,
  pyyaml,
  httpx2,
}:

buildPythonPackage rec {
  pname = "llm-semantic-search";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [ setuptools ];

  # llm: runtime import for @llm.hookimpl and llm.user_dir()
  # pyyaml: runtime import for parsing the YAML config file
  # httpx2: runtime import for HTTP requests to semsearch server
  propagatedBuildInputs = [ llm pyyaml httpx2 ];

  # No tests vendored.
  doCheck = false;

  pythonImportsCheck = [ "llm_semantic_search" ];

  meta = {
    description = "LLM plugin providing semantic search via semsearch HTTP server";
    homepage = "https://github.com/aldzikridp/semantic-search";
    license = lib.licenses.mit;
  };
}
