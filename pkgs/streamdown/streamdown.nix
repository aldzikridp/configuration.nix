# Nix derivation for `streamdown` — a streaming markdown renderer
# for modern terminals, part of the DAY50 suite of open-source AI tools.
#
# Upstream is published on PyPI as `streamdown`, but the source lives at
# github.com/day50-dev/render-markdown-terminal (the repo is named after
# the project's original working title). The dist name `streamdown` is
# what the [project.scripts] entry points (`streamdown` and `sd`) live
# under, and what `import streamdown` resolves to.
#
# Build it via:
#   pkgs.python3Packages.callPackage ./default.nix { }
#
# The derivation produces two CLI entry points (`streamdown` and `sd`),
# both pointing at `streamdown.sd:main`. They land on PATH automatically
# when the derivation is added to `home.packages` — no `withPackages`
# wrapping is needed because the package declares its own console
# scripts via `[project.scripts]` in pyproject.toml.
#
# Note on `sd.py`: the entry-point module is a bash/python polyglot.
# The first 19 lines are a bash prologue (`#!/usr/bin/env bash` plus a
# PEP 723 inline-metadata block) wrapped inside a Python triple-quoted
# string. From Python's point of view the file is a normal module that
# imports `main` from `streamdown.sdlib` and re-exports it. Hatchling
# handles this without issue.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  # Runtime deps — mirror [project.dependencies] in pyproject.toml.
  pygments,
  appdirs,
  toml,
  wcwidth,
  pylatexenc,
  # Optional extra from [project.optional-dependencies].images. Included
  # because requirements.txt and the PEP 723 inline metadata in sd.py
  # both list it — inline image rendering is a headline feature of the
  # CLI. Drop this if you want a slimmer build.
  term-image,
}:

buildPythonPackage rec {
  pname = "streamdown";
  version = "0.36.6";

  src = fetchFromGitHub {
    owner = "day50-dev";
    repo = "render-markdown-terminal";
    rev = "v${version}";
    # `lib.fakeHash` is a placeholder. The first `nix build` will fail
    # and print the correct SRI hash in the error output (look for a
    # line like `specified: sha256-0000...` and `got: sha256-XXXX...`).
    # Replace `lib.fakeHash` below with that `got:` value.
    #
    # Alternatively compute it directly without a build attempt:
    #   nix-prefetch-url --unpack --type sha256 \
    #     https://github.com/day50-dev/render-markdown-terminal/archive/refs/tags/v0.36.6.tar.gz
    #   nix hash to-sri --type sha256 <prefetch-output>
    #hash = lib.fakeHash;
    hash = "sha256-RL6dKFlCob+VRN+CEUAmvEWOMAuKs/l7fkb6PMU80Ik=";
  };

  pyproject = true;

  build-system = [ hatchling ];

  # All runtime deps are propagated so `streamdown` works as a
  # standalone CLI when this derivation is dropped straight into
  # `home.packages`. Without propagation, the entry-point wrapper
  # would fail to import its own libraries at runtime.
  propagatedBuildInputs = [
    pygments
    appdirs
    toml
    wcwidth
    pylatexenc
    term-image
  ];

  # Upstream ships a shell-based test suite under tests/ that shells
  # out to `sd` itself and compares ANSI-stripped output against
  # fixture files. Not appropriate for the Nix build sandbox (no TTY,
  # and the harness assumes a working `sd` on PATH). The library is
  # exercised in real usage by the LLM tools wired up in home/llm.nix.
  doCheck = false;

  pythonImportsCheck = [ "streamdown" ];

  meta = with lib; {
    description = "A streaming markdown renderer for modern terminals with syntax highlighting";
    homepage = "https://github.com/day50-dev/render-markdown-terminal";
    license = licenses.mit;
    mainProgram = "streamdown";
    platforms = platforms.unix;
  };
}
