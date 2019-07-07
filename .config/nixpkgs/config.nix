{
  allowUnfree = true; #allow proprietary software installed
  packageOverrides = pkgs: with pkgs; {
    master-x_Packages = pkgs.buildEnv {
      name = "desktop-gnome-masterx";
      paths = [
        chromium
        emacs
        firefox
        flashplayer-standalone
        libreoffice
        keepassxc
        htop
        jetbrains.jdk
        gimp
        gnome3.geary
        lollypop
        mpv
        neofetch
        neovim
        powerline-fonts
        source-code-pro
        tdesktop
        transmission-gtk
        weechat
        youtube-dl
      ];
    };
  };
}
