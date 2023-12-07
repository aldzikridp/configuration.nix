{ pkgs, ... }:
let
  chromiumArgs = [
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
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

in
{
  #security.chromiumSuidSandbox.enable = true;
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
    #(imv.override { withWindowSystem = "wayland"; })
    imv
    jq
    pavucontrol
    polkit_gnome
    udiskie
    wf-recorder
    xdragon
    slurp
    zathura
    #luakit
    #xournalpp
    thunderbird
    gnome.adwaita-icon-theme
    unstable.tdesktop
    dbus-sway-environment
    #(unstable.google-chrome.override {
    #  commandLineArgs = chromiumArgs;
    #})
    #unstable.google-chrome
    unstable.liferea
    unstable.rssguard
    #(ungoogled-chromium.override{
    #  commandLineArgs = chromiumArgs;
    #})
  ];

  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
