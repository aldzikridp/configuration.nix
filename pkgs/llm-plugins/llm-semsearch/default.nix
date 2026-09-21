# Nix derivation for the `llm-semsearch` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2 and §4 (pg-semantic-search injection).
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-semsearch";

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
