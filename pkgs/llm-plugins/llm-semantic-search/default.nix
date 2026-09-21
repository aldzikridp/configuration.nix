# Nix derivation for the `llm-semantic-search` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2.
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-32KbNtDEBowzMAYhWPaSeZEzs+oNRzGd9rKGGD5goMM=";
  }}/pkgs/llm-semantic-search";

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
