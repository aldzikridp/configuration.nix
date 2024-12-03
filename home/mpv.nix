{ pkgs, ... }:
{
  programs.yt-dlp.enable = true;
  programs.mpv = {
   enable = true;
   scripts = with pkgs.mpvScripts;[
    thumbfast
    quality-menu
    uosc
   ];
   scriptOpts = {
    thumbfast = {
      network = true;
    };
   };
   config = {
    osc = "no";
    hwdec = "yes";
    gpu-api = "vulkan";
    #ytdl-format = "[ext=mp4]";
    script-opts = "ytdl_hook-ytdl_path=yt-dlp";
   };
   defaultProfiles = [
    "high-quality"
   ];
  };
}
