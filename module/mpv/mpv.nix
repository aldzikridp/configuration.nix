{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import <nixpkgs-unstable>
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
