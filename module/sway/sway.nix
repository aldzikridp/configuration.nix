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
    xdragon
    slurp
    zathura
    thunderbird
    gnome.adwaita-icon-theme
    unstable.google-chrome
    unstable.onlyoffice-bin
    unstable.tdesktop
    (unstable.ungoogled-chromium.override{
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--disable-gpu-driver-bug-workarounds"
        "--enable-accelerated-video-decode"
        "--enable-features=VaapiVideoDecoder"
        "--use-gl=egl"
        "--show-avatar-button=never"
        "--hide-sidepanel-button=enable"
      ];
    })
  ];
}
