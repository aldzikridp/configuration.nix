{ pkgs, ... }:
let
  myrstudio = with pkgs; rstudioWrapper.override{ packages = with rPackages; [ ggplot2 dplyr xts ]; };
in
{
  environment.systemPackages = with pkgs; [
    myrstudio
  ];
}
