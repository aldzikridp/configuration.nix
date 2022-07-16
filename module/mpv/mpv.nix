{ config, pkgs, ... }:
let
  thumbnail-fork = pkgs.mpvScripts.thumbnail.overrideAttrs (oldAttrs: rec {
    src = pkgs.fetchFromGitHub {
      owner = "marzzzello";
      repo = "mpv_thumbnail_script";
      rev = "b2e58ad45e8b7b59b34c34648bc611b0b8816db4";
      sha256 = "1x131yywnply0k5gyl48ynrzpbc45zs7ggj2pa17lksaziz9h446";
    };
  });
  mympv = (pkgs.mpv-with-scripts.override {
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
