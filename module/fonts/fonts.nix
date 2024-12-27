{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      #(nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      noto-fonts
      noto-fonts-color-emoji
      nerdfonts
      roboto
      corefonts
    ];
    fontDir.enable = true;
  };
}
