{ config, pkgs, ... }:
let
  thumbnail-fork = pkgs.mpvScripts.thumbnail.overrideAttrs (oldAttrs: rec {
    src = pkgs.fetchFromGitHub {
      owner = "marzzzello";
      repo = "mpv_thumbnail_script";
      rev = "83d42716fb93382a4889c500f4634d4a96ce7361";
      sha256 = "1p88wzfp94wps0qf72hcvc8dbmqy3zgnic8vsma69cjll59j1c1r";
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
