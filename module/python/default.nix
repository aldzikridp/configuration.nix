{ pkgs, ... }:
let
  my-packages = python-packages: with python-packages; [
    pillow
    python-lsp-server
  ];
  my-python = pkgs.python3.withPackages my-packages;

in
{
  environment.systemPackages = with pkgs; [
    my-python
  ];
}
