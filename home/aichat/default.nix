{ pkgs, ... }:
{
  programs = {
    aichat.enable = true;
    pandoc.enable = true;
  };
  home.packages = with pkgs; [
    argc
    ctx7
  ];
}
