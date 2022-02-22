{ pkgs, ... }:
let
  my-packages = python-packages: with python-packages; [
    pillow
    python-lsp-server
  ];
  my-python = pkgs.python3.withPackages my-packages;

  jupyterWithBatteries = pkgs.jupyter.override {
    python3 = pkgs.python3.withPackages (ps: with ps; [
      numpy
      scipy
      matplotlib
      pandas
    ]);
  };


in
{
  environment.systemPackages = with pkgs; [
    my-python
    jupyterWithBatteries
  ];
}
