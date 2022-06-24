{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import <nixpkgs-unstable> {};
in
{
  environment.systemPackages = with pkgs; [
    unstable.endless-sky
  ];
}
