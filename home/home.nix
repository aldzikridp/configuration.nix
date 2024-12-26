{ pkgs, ... }:
{
  imports = [
    ./foot.nix
    ./sway
    ./lf.nix
    ./mpv.nix
    ./mpd.nix
    ./ncmpcpp
    ./zathura.nix
    ./bash.nix
    ./fzf.nix
    ./firefox
    ./neovim
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
    (libsForQt5.callPackage ../pkgs/qqsp/default.nix { })
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
    nil
    buku
    p7zip
    btop
    chezmoi
    jq
    brightnessctl
    pavucontrol
    ctpv
    wl-clipboard
    xdragon
    grim
    openttd
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
