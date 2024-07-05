{ lib, pkgs, ... }:
let
  thumbnail-fork = pkgs.mpvScripts.thumbnail.overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "marzzzello";
      repo = "mpv_thumbnail_script";
      rev = "6b6e1a279fb13387221ed8fb4d50aa560ed10f7e";
      sha256 = "sha256-XVPcL3/XOnXl7nVkwlgrBaTO5mqB5ULQnmIhVDQtoP0=";
      #sha256 = lib.fakeSha256;
    };
  });
  mympv = (pkgs.mpv.override {
    scripts = with pkgs.mpvScripts; [
     thumbnail
    ];
  });
in
{
  environment.systemPackages = with pkgs; [
    unstable.yt-dlp
    mympv
  ];
}
