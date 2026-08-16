{
  lib,
  buildPythonPackage,
  llm,
  setuptools,
}:

buildPythonPackage rec {
  pname = "llm-file-tools";
  version = "0.4.0";
  pyproject = true;

  # Vendored source: llm_file_tools.py + pyproject.toml sit next to this file.
  # Mirrors the pattern used by pkgs/llm-plugins/llm-ctx7, pkgs/llm-plugins/llm-wikipedia, etc.
  src = ./.;

  build-system = [ setuptools ];

  # `llm` is a runtime import (@llm.hookimpl), so propagate it.
  propagatedBuildInputs = [ llm ];

  # Tests need ripgrep + git at runtime and a configured git identity;
  # skip them in the build sandbox. The plugin's behaviour is verified
  # at runtime via `llm tools list`.
  doCheck = false;

  pythonImportsCheck = [ "llm_file_tools" ];

  meta = {
    description = "An llm plugin: read_file, write_file, patch_file, apply_diff, list_dir, grep_file (ripgrep+grep), git_apply.";
    homepage = "https://github.com/aldzikridp/configuration.nix";
    license = lib.licenses.asl20;
    # NOTE: do NOT set mainProgram = null — newer nixpkgs propagates it into
    # env as NIX_MAIN_PROGRAM and env values can't be null.
    # This package is a plugin library, not a CLI, so no mainProgram at all.
  };
}
