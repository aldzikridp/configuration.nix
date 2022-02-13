{ pkgs, ... }:
with pkgs;
let
  myRStudio = rstudioWrapper.override{ packages = with rPackages; [ ggplot2 dplyr xts ]; };
  myRPackage = rWrapper.override{ packages = with rPackages; [ ggplot2 dplyr xts languageserver ]; };
in
{
  environment.systemPackages = with pkgs; [
    myRStudio
    myRPackage
  ];
}
