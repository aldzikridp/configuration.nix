{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  squalus_nix = import
    (builtins.fetchTarball https://github.com/squalus/nixpkgs/archive/refs/heads/librewolf.tar.gz){};
in
{
  environment.systemPackages = with pkgs; [
    squalus_nix.librewolf
  ];
}
