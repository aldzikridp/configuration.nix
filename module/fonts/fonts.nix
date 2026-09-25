{ pkgs, lib, ... }:
let
  nerdfonts = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
in
{
  fonts = {
    packages = [
      #(nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
      pkgs.roboto
      pkgs.corefonts
      pkgs.noto-fonts-cjk-sans
    ] ++ nerdfonts ;
    fontDir.enable = true;
  };
}
