# Shared `pythonPackagesExtensions` for every consumer that must agree on
# pinned Python package versions.
#
# Consumers (all must extend the SAME base set, currently `pkgs.unstable`):
#   - home/llm.nix        → the `llm` CLI environment (py3.14)
#   - home/home.nix       → the standalone `semsearch` CLI (py3.14)
#
# Why shared: `pg-semantic-search` passes an httpx2.Client into the OpenAI
# SDK, which hard-fails on version mismatch ("Expected an instance of
# `httpx.Client`"). If any env resolves a different `openai` major than the
# others, that env breaks at runtime. Keeping the pins in ONE extension list
# guarantees a single shared openai derivation across all these environments.
#
# Usage:
#   myPkgs = pkgs.unstable.extend (import ./python-package-extensions.nix);
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    # Disable tests on courlan/trafilatura.
    # courlan 1.3.2's test suite is broken on Python 3.13 (urllib.robotparser
    # no longer initializes `groups` until `parse()` is called). The library
    # works fine at runtime; only tests fail.
    # Track upstream: https://github.com/adbar/courlan/issues
    (python-final: python-prev: {
      courlan = python-prev.courlan.overridePythonAttrs (old: {
        doCheck = false;
      });
      trafilatura = python-prev.trafilatura.overridePythonAttrs (old: {
        doCheck = false;
      });
    })

    # Version bumps + the OpenAI SDK pin.
    # `final` here is the top-level extended pkgs (`pkgs.unstable.extend …`),
    # which provides fetchFromGitHub.
    (python-final: python-prev: {
      # Pin the OpenAI Python SDK to 3.3.1
      # (https://github.com/openai/openai-python/releases/tag/v3.3.1).
      # Applies to BOTH consumers built from the extended set: the `llm`
      # CLI env (llm + llm-openrouter-embeddings) and `pg-semantic-search`
      # (via its langchain-openai dependency). Version bounds like
      # openai>=1.x are still satisfied by 3.3.1.
      openai = python-prev.openai.overridePythonAttrs (old: {
        version = "3.3.1";
        src = final.fetchFromGitHub {
          owner = "openai";
          repo = "openai-python";
          tag = "v3.3.1";
          hash = "sha256-mHeEVOYU3rku2Cmd/aOzqvduvod97txCtnoLBVsz5EA=";
        };
        # nixpkgs' postPatch relaxes a PINNED hatchling version in
        # pyproject.toml so the build works against nixpkgs' own hatchling.
        # That pattern targets the older nixpkgs-openai source
        # (hatchling==1.26.3); v3.3.1 pins 1.27.0, so re-do the same
        # relaxation with the correct version (without this, pypa build
        # fails: nixpkgs ships hatchling 1.31.0 which doesn't satisfy the
        # exact ==1.27.0 pin).
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail "hatchling==1.27.0" "hatchling" \
            --replace-fail "jiter>=0.16.0" "jiter>=0.12"
        '';
        # v3.3.1 switched its HTTP layer from httpx to httpx2
        # (httpx2>=2.7.0,<3); nixpkgs' openai 2.41.1 expression predates
        # that switch, so add httpx2 explicitly. The jiter floor is
        # relaxed to nixpkgs' 0.12.0 in postPatch — v3.3.1 only uses
        # jiter.from_json, which 0.12 provides.
        dependencies = old.dependencies ++ [ python-final.httpx2 ];
        doCheck = false;
      });

      condense-json = python-prev.condense-json.overridePythonAttrs (old: {
        version = "1.1";
        src = final.fetchFromGitHub {
          owner = "simonw";
          repo = "condense-json";
          tag = "1.1";
          hash = "sha256-IBYjDFhbQlZ/17nTo5FvJM7aeadKS5dW7J8IGy4956M=";
        };
        # 1.1's test suite needs `hypothesis`, which the 0.1.3
        # derivation doesn't provide; skip tests (library works fine).
        doCheck = false;
      });

      llm = python-prev.llm.overridePythonAttrs (old: {
        version = "0.33";
        src = final.fetchFromGitHub {
          owner = "simonw";
          repo = "llm";
          tag = "0.33";
          hash = "sha256-EXyEeSNtxF3xbGAaQwSFXRTHN4p/BzxqAW90gleeXEo=";
        };
        # Drop nixpkgs' install/uninstall-disable patch and the
        # @listOfPackagedPlugins@ postPatch substitution (the other
        # bundled patches target 0.31.1-specific code and may not apply
        # to 0.32). Plugins are managed via Nix, so `llm install` is
        # unused.
        patches = [];
        postPatch = "";
        doCheck = false;
      });
    })
  ];
}
