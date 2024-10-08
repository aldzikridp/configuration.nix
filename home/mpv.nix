{ pkgs, ... }:
{
  programs.yt-dlp.enable = true;
  programs.mpv = {
   enable = true;
   scripts = with pkgs.mpvScripts;[
    thumbnail
   ];
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
