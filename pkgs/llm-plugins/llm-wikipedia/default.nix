# Nix derivation for the `llm-wikipedia` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2.
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-wikipedia";

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
