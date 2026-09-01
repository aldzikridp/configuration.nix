# Nix derivation for the `llm-fetch-url` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See PLAN.md:§2.2.
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    rev = "v0.1.0";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-fetch-url";

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
