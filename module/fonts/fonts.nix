{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      #(nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      nerdfonts
      emojione
      roboto
      corefonts
    ];
    fontDir.enable = true;
  };
}
