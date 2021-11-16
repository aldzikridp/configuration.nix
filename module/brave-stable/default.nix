{ pkgs, ... }:

{
  nixpkgs.overlays =
    [ (self: super: { brave-stable = super.callPackage ./brave.nix { }; }) ];

  environment.systemPackages = with pkgs; [
    pkgs.brave-stable
  ];
}

