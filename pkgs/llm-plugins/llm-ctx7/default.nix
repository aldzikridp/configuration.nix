# Nix derivation for the `llm-ctx7` plugin — fetch wrapper.
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
  pname = "llm-ctx7";
  version = "0.1.0";
  pyproject = true;

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-32KbNtDEBowzMAYhWPaSeZEzs+oNRzGd9rKGGD5goMM=";
  }}/pkgs/llm-ctx7";

  build-system = [ setuptools ];

  propagatedBuildInputs = [ llm ];

  doCheck = false;

  pythonImportsCheck = [ "llm_ctx7" ];

  meta = {
    description = "LLM plugin providing a ctx7_search tool (ported from aichat).";
    homepage = "https://github.com/sigoden/aichat";
    license = lib.licenses.mit;
  };
}
