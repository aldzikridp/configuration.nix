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

  # Private Git repo, required to add environemtn var to nix-daemon
  # with below option in configuration.nix, put the credentials in file
  # used in value.
  # Put this in configuration.nix -> systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";
  private = true;
  rev = "a2598ac6d5bd18572e1bee69297872c342c6dc07";
  hash = "sha256-Y+RFNT5Q7nLRjQznrjpaBdRA8ax9ZCZw3lySJgPTscc=";
  #hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
