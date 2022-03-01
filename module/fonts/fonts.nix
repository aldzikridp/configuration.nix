{ pkgs, lib, ... }:
{
  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      roboto
      corefonts
    ];
    fontDir.enable = true;
  };
}
