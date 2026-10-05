# mcpc — a minimal Model Context Protocol client, bridged to the shell.
#
# Bridge an MCP server to `mcpc list/call/read/stop` so an agent reaches
# MCP-only capabilities through the command tool it already has. Standard
# library only, no coroutines.
#
# Build via:
#   pkgs.python3Packages.callPackage ../pkgs/mcpc/default.nix { }
#
# Runtime config: $HAX_MCP_CONFIG or ~/.config/hax/mcp/config.json (write it
# with home.file — see the configuration.nix example in the upstream README).
# A server with `command` is spawned per call; a server with `url` is called
# over streamable HTTP, and `npx`-wrapped servers need nodejs on PATH.
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  setuptools,
}:

buildPythonApplication rec {
  pname = "hax-mcp-bridge";
  version = "0.1.0";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "aldzikridp";
    repo = "mcpc";
    rev = "8eba1f537e49d568ec17500fa04f77b35840e622";
    #hash = lib.fakeHash;
    hash = "sha256-u00eybroFASwhHuqOO5xlUlta+u/J1K8NxgNA888Dsg=";
  };

  build-system = [ setuptools ];

  # No dependencies: pyproject.toml leaves [project.dependencies] empty on
  # purpose — adding one here defeats the point of the bridge.
  dependencies = [ ];

  # The console entry point is `mcpc`, but the module stays `mcp_bridge`
  # (py-modules + package-dir in pyproject.toml).
  pythonImportsCheck = [ "mcp_bridge" ];

  # Upstream's own self-check: result rendering, the SSE reply decoder,
  # config resolution, and a JSON-RPC round trip against a stub server.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python scripts/mcp_bridge_selftest.py
    runHook postCheck
  '';

  meta = {
    description = "Minimal Model Context Protocol client (list, call, read, stop)";
    homepage = "https://github.com/aldzikridp/mcpc";
    license = lib.licenses.mit;
    mainProgram = "mcpc";
    platforms = lib.platforms.unix;
  };
}
