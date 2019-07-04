{
  allowUnfree = true; #allow proprietary software installed
  packageOverrides = pkgs: with pkgs; {
    master-x_Packages = pkgs.buildEnv {
      name = "desktop-gnome-masterx";
      paths = [
        chromium
        firefox
        flashplayer-standalone
        libreoffice
        keepassxc
        htop
        jetbrains.jdk
        gnome3.geary
        lollypop
        mpv
        neofetch
        powerline-fonts
        tdesktop
        transmission-gtk
        weechat
      ];
    };
  };
}
