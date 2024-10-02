{ pkgs, ... }:
{
  imports = [
    ./kitty-conf.nix
    ./waybar.nix
    ./wofi.nix
    ./lf.nix
    ./mpv.nix
    ./mpd.nix
    ./ncmpcpp
    ./zathura.nix
    ./bash.nix
  ];
  home.packages = with pkgs;[
    ctpv
    #(pkgs.callPackage ../pkgs/rifle/default.nix { })
    (transmission_4.override { enableCli = false; })
  ];
  programs = {
    lazygit.enable = true;
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  home.stateVersion = "24.05";
}
