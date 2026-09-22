# llm-file-tools: slices /pkgs/llm-file-tools out of the shared llm-plugins checkout
# (rev/hash pinned once in ../source.nix; Nix deduplicates the fetch).
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

  src = "${fetchFromGitHub (import ../source.nix)}/pkgs/llm-file-tools";

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
