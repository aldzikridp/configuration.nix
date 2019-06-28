{
  packageOverrides = pkgs: with pkgs; {
    master-x_Packages = pkgs.buildEnv {
      name = "desktop-gnome-masterx";
      paths = [
        firefox
        libreoffice
        keepassxc
        htop
        lollypop
        mpv
        neofetch
        powerline-fonts
        tdesktop
        transmission-gtk
      ];
    };
  };
}
