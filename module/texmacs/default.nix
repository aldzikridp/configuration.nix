{ lib, pkgs, ... }:

let
  mytexmacs = pkgs.libsForQt5.callPackage ./texmacs.nix {
    tex = pkgs.texlive.combined.scheme-full;
    extraFonts = true;
  };

in
{
  environment.systemPackages = with pkgs; [
    mytexmacs
  ];
}
