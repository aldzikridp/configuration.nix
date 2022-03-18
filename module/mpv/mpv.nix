{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import <nixpkgs-unstable>
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  mympv = with mpvScripts; mpv-with-scripts.override {
    scripts = [
      thumbnail
      mpv-playlistmanager
    ]; };
in
{
  environment.systemPackages = with pkgs; [
    unstable.yt-dlp
    mympv
  ];
}
