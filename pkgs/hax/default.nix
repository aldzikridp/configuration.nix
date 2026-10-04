# hax — minimalist, terminal-native coding agent written in C.
#
# Build via:
#   pkgs.callPackage ../pkgs/hax/default.nix { }
#
# Runtime: hax shells out to bash (falls back to /bin/sh, which NixOS provides),
# and optionally to git/less/fzf and the clipboard helpers for its opt-in
# features; those are plain PATH lookups, so install what you use.
{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  curl,
  jansson,
}:

let
  version = "0.5.0";
in
stdenv.mkDerivation {
  pname = "hax";
  inherit version;

  # The release tarball is the source of record for packaging: upstream builds it
  # from the same commit CI tested, and with no .git present meson's vcs_tag()
  # stamps exactly the declared version ("v0.5.0") instead of a git-describe
  # string. Same choice as the AUR package.
  src = fetchurl {
    url = "https://github.com/OleksandrChekhovskyi/hax/releases/download/v${version}/hax-${version}.tar.xz";
    hash = "sha256-waFcNUlpuHAPcv+nt+7g7DXXALIp9W8GeBQjf8AFJYY=";
  };

  strictDeps = true;

  # python3 is needed at configure time: tests/meson.build resolves the e2e
  # runner with find_program('python3'), even though those tests are not run here.
  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ];

  # libcurl for HTTPS, jansson for JSON — hax's only two link deps.
  buildInputs = [
    curl
    jansson
  ];

  # Build only the program: the ~100 C test binaries are not run in this build.
  ninjaFlags = [ "hax" ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    # Upstream CI runs the full meson suite (and the tmux-driven e2e scenarios);
    # here a smoke test keeps tmux and the network fixtures out of the sandbox.
    ./hax --version | grep -qx "hax v${version}"
    runHook postCheck
  '';

  meta = {
    description = "Minimalist, terminal-native coding agent written in C";
    homepage = "https://github.com/OleksandrChekhovskyi/hax";
    license = lib.licenses.mit;
    mainProgram = "hax";
    # Upstream supports Linux, macOS, and the BSDs; only Linux is exercised here.
    platforms = lib.platforms.unix;
  };
}
