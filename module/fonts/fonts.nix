{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      roboto
      corefonts
    ];
    fontDir.enable = true;
  };
}
