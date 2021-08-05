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
      wofi
      waybar
      xwayland
    ];
  };
  nixpkgs.config.pulseaudio = true; #pulse support for waybar

  environment.systemPackages = with pkgs; [
    brightnessctl
    imv
    jq
    pavucontrol
    polkit_gnome
    udiskie
    wf-recorder
    slurp
    zathura
  ];
}
