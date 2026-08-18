# Nix derivation for the `llm-semsearch` plugin.
#
# Provides the `semantic_search` tool for llm, backed by semsearch's
# Python library (SemanticSearchService). Reads search defaults from
# <llm.user_dir()>/semantic-search.yaml.
#
# Build via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# Then inject it into the llm python env (see home/llm.nix).
# semsearch itself is a transitive dependency — no need to add it
# to withPackages separately.
{
  lib,
  buildPythonPackage,
  setuptools,
  llm,
  pyyaml,
  pg-semantic-search,
}:

buildPythonPackage rec {
  pname = "llm-semsearch";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [ setuptools ];

  # llm: runtime import for @llm.hookimpl and llm.user_dir()
  # pyyaml: runtime import for parsing the YAML config file
  # pg-semantic-search: runtime import for SemanticSearchService / get_settings
  propagatedBuildInputs = [ llm pyyaml pg-semantic-search ];

  # No tests vendored.
  doCheck = false;

  pythonImportsCheck = [ "llm_semsearch" ];

  meta = {
    description = "LLM plugin providing semantic search over local documents via semsearch";
    homepage = "https://github.com/aldzikridp/semantic-search";
    license = lib.licenses.mit;
  };
}
