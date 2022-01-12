{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  mympv = mpv-with-scripts.override { scripts = [ mpvScripts.thumbnail ]; };
in
{
  environment.systemPackages = with pkgs; [
    unstable.yt-dlp
    mympv
  ];
}
