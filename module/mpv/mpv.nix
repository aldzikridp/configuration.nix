{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in 
{
    environment.systemPackages = with pkgs; [
        unstable.yt-dlp
    ];
}
