{ pkgs, ... }:
{
  # Sway polkit
  security.polkit.enable = true;
  environment.pathsToLink = [ "/libexec" ];
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      grim
      mako
      kitty
      waybar
      xwayland
      wdisplays
    ];
  };
  nixpkgs.config.pipewire = true; #pipewire support for waybar

  environment.systemPackages = with pkgs; [
    brightnessctl
    (imv.override{withWindowSystem="wayland";})
    jq
    pavucontrol
    polkit_gnome
    udiskie
    wf-recorder
    slurp
    zathura
    thunderbird
    gnome.adwaita-icon-theme
    unstable.google-chrome
    unstable.onlyoffice-bin
    unstable.tdesktop
  ];
}
