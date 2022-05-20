{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./module/systemd-boot/boot.nix
      ./module/network/networking.nix
      ./module/network/dnscrypt.nix
      ./module/network/dnsmasq-adblock
      ./module/virtualisation
      ./module/neovim/neovim.nix
      ./module/mpv/mpv.nix
      ./module/sway/sway.nix
      ./module/fonts/fonts.nix
      ./module/python
      ./module/firefox
      ./thinkpad.nix
    ];

  services.earlyoom.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bat
    btop
    gcc
    fd
    ffmpeg-full
    fzf
    git
    gitui
    htop
    imagemagick
    keepassxc
    ncdu
    whois
    ranger
    rclone
    ripgrep
    rsync
    rclone
    rnix-lsp
    starship
    steam-run-native
    wget2
    texlab
    texlive.combined.scheme-full
    transmission
    unzip
    dnsutils
    zip
    killall
    gnumake
    (ncmpcpp.override {
      visualizerSupport = true;
    })
    mpc_cli
    mpd
    unrar-wrapper
  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gnome3";
  };

  #Games
  #nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"
    "corefonts"
  ];
  programs.steam.enable = true;


  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  #services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.master-x = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "networkmanager" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.09"; # Did you read the comment?

}
