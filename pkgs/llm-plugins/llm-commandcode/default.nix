# Nix derivation for the `llm-commandcode` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources (.py/.toml/README) remain on disk until T7; src now
# slices into the fetched tree. See llm-plugins/README.md and PLAN.md:§2.2.
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

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    private = true;
    rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-32KbNtDEBowzMAYhWPaSeZEzs+oNRzGd9rKGGD5goMM=";
  }}/pkgs/llm-commandcode";

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
