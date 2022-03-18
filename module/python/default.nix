{ pkgs, ... }:
let
  my-packages = python-packages: with python-packages; [
    pillow
  ];
  my-python = pkgs.python3.withPackages my-packages;

in
{
  environment.systemPackages = with pkgs; [
    my-python
  ];
}
