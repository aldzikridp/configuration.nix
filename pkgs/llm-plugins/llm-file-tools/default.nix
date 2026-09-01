# Nix derivation for the `llm-file-tools` plugin — fetch wrapper.
#
# Fetches source from github:aldzikridp/llm-plugins (Pattern A per-default.nix).
# Vendored sources remain on disk until T7. See llm-plugins/README.md and PLAN.md:§2.2.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  llm,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-file-tools";
  version = "0.4.0";
  pyproject = true;

  src = "${fetchFromGitHub {
    owner = "aldzikridp";
    repo = "llm-plugins";
    rev = "v0.1.0";
    hash = "sha256-234Uo2yNZBImZIGQA/TIPVG3wZrRQt0GJF3h21B61QY=";
  }}/pkgs/llm-file-tools";

  build-system = [ setuptools ];

  propagatedBuildInputs = [ llm ];

  doCheck = false;

  pythonImportsCheck = [ "llm_file_tools" ];

  meta = {
    description = "An llm plugin: read_file, write_file, patch_file, apply_diff, list_dir, grep_file (ripgrep+grep), git_apply.";
    homepage = "https://github.com/aldzikridp/configuration.nix";
    license = lib.licenses.asl20;
  };
}
