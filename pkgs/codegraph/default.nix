# Nix derivation for `codegraph`.
#
# Pre-indexed code knowledge graph that auto-syncs on code changes, for
# Claude Code, Codex, Gemini, Cursor, OpenCode, and other AI coding agents.
# 100% local, fewer tokens, fewer tool calls.
#
# Build via:
#   pkgs.callPackage ../pkgs/codegraph/default.nix { }
#
# Usage:
#   codegraph --help        # Show all commands
#
# See https://github.com/colbymchenry/codegraph for full docs.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:

buildNpmPackage rec {
  pname = "codegraph";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "colbymchenry";
    repo = "codegraph";
    rev = "81e1f4a92fdbd9413ba73cf72c8a5408102a7897";
    hash = "sha256-FHfUU9Qd0xDtomFZXEejUXDCeHRozn9caevhmTJaufc=";
  };

  npmDepsHash = "sha256-7cGlc4q+9DoPsyPDos5BfE9n2Qmvlvl8QEDiD/y6+e0=";

  # The package.json build script compiles TypeScript and copies assets
  npmBuildScript = "build";

  # Ensure Node.js is available at runtime
  buildInputs = [ nodejs ];

  # Tests require file system access and are not suitable for the sandbox
  doCheck = false;

  meta = with lib; {
    description = "Pre-indexed code knowledge graph for AI coding agents";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = licenses.mit;
    mainProgram = "codegraph";
    platforms = platforms.linux;
  };
}
