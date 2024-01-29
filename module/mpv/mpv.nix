{ config, pkgs, ... }:
let
  thumbnail-fork = pkgs.mpvScripts.thumbnail.overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "marzzzello";
      repo = "mpv_thumbnail_script";
      rev = "933a396f82847451911f5ba76cad4fcade69c37c";
      sha256 = "0k7mxd9c38igaqghq0rdwl3m7lg3567yc80886zms6jhy8ymskcn";
    };
  });
  mympv = (pkgs.mpv.override {
    scripts = [
      thumbnail-fork
    ];
  });
in
{
  environment.systemPackages = with pkgs; [
    unstable.yt-dlp
    mympv
  ];
}
