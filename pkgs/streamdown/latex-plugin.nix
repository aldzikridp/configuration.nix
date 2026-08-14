# Nix derivation for `streamdown` with the `latex` plugin added.
#
# This is a thin wrapper around the existing `pkgs/streamdown/default.nix`
# in this repo. It calls the original derivation, then applies
# `overrideAttrs` to inject a `postPatch` step that copies our vendored
# `latex.py` into the source tree's `streamdown/plugins/` directory
# before hatchling builds the wheel.
#
# Why `postPatch` and not `postInstall`?
# --------------------------------------
# streamdown plugins are file-based, not entry-point-based. The upstream
# `pyproject.toml` declares:
#
#   [tool.hatch.build.targets.wheel]
#   packages = ["streamdown"]
#   include = ["streamdown/plugins/*"]
#
# So hatchling bundles every `.py` file in `streamdown/plugins/` into the
# wheel at build time. If we copy our plugin in AFTER the wheel is built
# (i.e. `postInstall`), it lands in the nix store as a separate file that
# Python's import system can't find — `import streamdown.plugins.latex`
# would fail because the wheel's RECORD doesn't list it.
#
# By copying in `postPatch` (which runs AFTER `unpackPhase` extracts the
# source, but BEFORE `buildPhase` invokes hatchling), our plugin becomes
# part of the source tree, hatchling bundles it into the wheel, and the
# resulting `streamdown.plugins.latex` module is importable normally.
#
# Usage
# -----
# In `home/home.nix`, replace:
#
#   (pkgs.python3Packages.callPackage ../pkgs/streamdown/default.nix { })
#
# with:
#
#   (pkgs.python3Packages.callPackage ../pkgs/streamdown/latex-plugin.nix { })
#
# The `latex-plugin.nix` file calls the original `default.nix` and applies
# the override — no other changes needed.
#
# Verifying
# ---------
# After `nixos-rebuild switch`, the plugin is active. streamdown discovers
# plugins by scanning `streamdown/plugins/*.py` at runtime and calling each
# module's top-level `Plugin(text, state, style)` function. To confirm:
#
#   $ python3 -c "from streamdown.plugins import latex; print(latex.Plugin)"
#   <function Plugin at 0x...>
#
# The latex plugin converts `$$...$$` LaTeX blocks to plain text using
# `pylatexenc` (which is already a runtime dep of the base streamdown
# derivation, so no new dependencies are introduced).

{ lib, callPackage, ... }@args:

let
  # 1. Build the base streamdown package from the existing derivation.
  #    `callPackage` resolves all the deps (pygments, appdirs, toml,
  #    wcwidth, pylatexenc, term-image, hatchling) from python3Packages.
  base = callPackage ./default.nix { };
in
base.overrideAttrs (old: {
  # 2. Add `latex.py` to the source tree before the wheel build.
  #    `${./latex.py}` is a store-path reference to the vendored file
  #    sitting next to this nix file. `cp` puts it into the unpacked
  #    source's `streamdown/plugins/` directory; hatchling's
  #    `include = ["streamdown/plugins/*"]` then bundles it.
  postPatch = (old.postPatch or "") + ''
    cp ${./latex.py} streamdown/plugins/latex.py
  '';

  # 3. Make sure the import check still passes with the extra plugin.
  #    The base derivation sets `pythonImportsCheck = [ "streamdown" ]`
  #    which is unaffected. We additionally verify the plugin module
  #    is importable.
  pythonImportsCheck = (old.pythonImportsCheck or [ "streamdown" ]) ++ [
    "streamdown.plugins.latex"
  ];

  # 4. Update the meta description so `nix profile` / `nix-env` users
  #    can tell at a glance this is the latex-patched variant.
  meta = (old.meta or { }) // {
    description = (old.meta or { }).description or "" + " (with latex plugin)";
    longDescription = (old.meta or { }).longDescription or ""
      + "\n\nThis build includes the custom latex plugin (streamdown/plugins/latex.py) "
      + "that converts $$...$$ LaTeX blocks to plain text via pylatexenc.";
  };
})
