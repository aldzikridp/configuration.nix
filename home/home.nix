{ pkgs, ... }:
{
  imports = [
    ./kitty-conf.nix
    ./sway
    ./lf.nix
    ./mpv.nix
    ./mpd.nix
    ./ncmpcpp
    ./zathura.nix
    ./bash.nix
    ./firefox
  ];
  home.packages = with pkgs;[
    jq
    brightnessctl
    pavucontrol
    ctpv
    wl-clipboard
    xdragon
    grim
    thunderbird
    tdesktop
    liferea
    xournalpp
    #(pkgs.callPackage ../pkgs/rifle/default.nix { })
    (transmission_4.override { enableCli = false; })
  ];
  programs = {
    lazygit.enable = true;
    gpg.enable = true;
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
  # Optional, hint Electron apps to use Wayland:
  fonts.fontconfig.enable = true;
  services.gpg-agent.enable = true;
  services.udiskie.enable = true;
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  home.stateVersion = "24.05";
}
