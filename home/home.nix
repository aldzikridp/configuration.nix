{ pkgs, ... }:
{
  imports = [
    ./foot.nix
    ./sway
    ./lf
    #./yazi.nix
    ./mpv.nix
    ./mpd.nix
    ./ncmpcpp
    ./zathura.nix
    ./bash.nix
    ./fzf.nix
    ./firefox
    ./neovim
    ./aichat
    ./llm.nix
  ];
  home.packages = with pkgs;[
    gopass
    pwgen
    ffmpeg-full
    ffmpegthumbnailer # video thumbnail
    kopia
    ripgrep
    rmpc
    rsync
    rclone
    (pkgs.callPackage ../pkgs/fzf-tab/default.nix { })
    #(libsForQt5.callPackage ../pkgs/qqsp/default.nix { })
    pamixer
    unrar-wrapper
    unzip
    whois
    zbar #for QR
    zip
    parallel
    bat 
    fd
    imagemagick
    lazygit
    lua-language-server
    nixd
    buku
    p7zip
    btop
    chezmoi
    jq
    brightnessctl
    pavucontrol
    grim
    openttd
    thunderbird
    telegram-desktop
    tor-browser
    ayugram-desktop
    liferea
    xournalpp
    #(pkgs.callPackage ../pkgs/rifle/default.nix { })
    #(transmission_4.override { enableCli = false; })
    transmission_4
    unstable.opencode
    context7-mcp
    rtk
    (pkgs.callPackage ../pkgs/term-llm/default.nix { })
    (pkgs.python3Packages.callPackage ../pkgs/streamdown/latex-plugin.nix { })
  ];
  programs = {
    lazygit.enable = true;
    gpg.enable = true;
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = false;
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };
  # Optional, hint Electron apps to use Wayland:

  fonts.fontconfig.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 43200;
    maxCacheTtl = 43200;
  };
  services.udiskie.enable = true;
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  home.stateVersion = "24.05";
}
