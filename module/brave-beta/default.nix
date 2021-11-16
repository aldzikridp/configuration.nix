{ pkgs, ... }:

{
  nixpkgs.overlays =
    [ (self: super: { brave-beta = super.callPackage ./brave.nix { }; }) ];

  environment.systemPackages = with pkgs; [
    pkgs.brave-beta
  ];
}

