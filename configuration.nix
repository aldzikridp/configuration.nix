{ config, pkgs, lib, ... }:

{
  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nixVersions.nix_2_8
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  imports =
    [
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
    ];



  services.earlyoom.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    _7zz
    bat
    btop
    gcc
    chezmoi
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
    rnix-lsp
    starship
    #steam-run-native
    transmission
    unzip
    dnsutils
    zip
    killall
    nix-serve
    gnumake
    (ncmpcpp.override {
      visualizerSupport = true;
    })
    mpc_cli
    mpd
    unrar-wrapper
    unstable.texlive.combined.scheme-full
    unstable.texlab
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
  #hardware.opengl.package = pkgs.old.mesa.drivers;

  users.users.master-x = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "networkmanager" ];
    #Generate hashed password with "mkpasswd -m sha-512"
    hashedPassword = "$6$WoF9RxiLei5iC5zp$UyckvU7P3yhaptLOKyPohWkXNcfd7UuQEWif5jjyOVRcz7qiPv3B47ap4LV5OChS8QeV1xehzYJMk.mI7S2rf0";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.05"; # Did you read the comment?

}
