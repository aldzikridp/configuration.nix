{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz){};
in
{
  environment.systemPackages = with pkgs; [
    unstable.librewolf-wayland
  ];
}
