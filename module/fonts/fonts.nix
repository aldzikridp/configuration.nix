{ pkgs, ... }:
{
  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      roboto
    ];
    fontDir.enable = true;
  };
}
