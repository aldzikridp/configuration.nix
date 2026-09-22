# Repo-wide source for the 9 wrappers in this directory.
#
# Each `<name>/default.nix` fetches this one repo and slices
# "/pkgs/<name>" out of it:
#
#   src = "${fetchFromGitHub (import ../source.nix)}/pkgs/<name>";
#
# Nix deduplicates the identical fixed-output fetch, so the repo is
# downloaded and built once no matter how many wrappers import this file.
# Keeping rev/hash here (and nowhere else) is what prevents the wrappers
# from drifting out of sync with each other.
#
# Bump procedure: edit `rev`, then `nix flake prefetch
# github:aldzikridp/llm-plugins/<rev> --json` and replace `hash` with the
# `narHash` it prints. The repo is private, so the prefetch needs
# git/netrc credentials.
{
  owner = "aldzikridp";
  repo = "llm-plugins";
  private = true;
  rev = "4957ab2a28116a16ee098667fec33641bb3d44f8";
  hash = "sha256-32KbNtDEBowzMAYhWPaSeZEzs+oNRzGd9rKGGD5goMM=";
}
