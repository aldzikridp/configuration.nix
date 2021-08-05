{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      firmwareLinuxNonfree = super.firmwareLinuxNonfree.overrideAttrs (old: rec {
        pname = "firmware-linux-nonfree";
        version = "2021-03-15";
        src = super.fetchgit {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
          rev = "refs/tags/" + super.lib.replaceStrings [ "-" ] [ "" ] version;
          sha256 = "sha256-BnYqveVFJk/tVYgYuggXgYGcUCZT9iPkCQIi48FOTWc=";
        };
        outputHash = "sha256-TzAMGj7IDhzXcFhHAd15aZvAqyN+OKlJTkIhVGoTkIs=";
      });
    })
  ];

  imports =
    [
      ./hardware-configuration.nix
      ./module/systemd-boot/boot.nix
      ./module/neovim/neovim.nix
    ];


  networking.hostName = "EVA-02"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Enable dnscrypt client
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = false;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  services.earlyoom.enable = true;

  # Enable docker service
  virtualisation.docker.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    aria
    firefox-wayland
    brightnessctl
    clang
    fd
    ffmpeg
    fzf
    git
    gnupg
    htop
    imagemagick
    imv
    jq
    keepassxc
    mpv
    p7zip
    pavucontrol
    polkit_gnome
    ranger
    ripgrep
    rsync
    slurp
    starship
    udiskie
    wf-recorder
    wget
    zathura
  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  # programs.zsh.enable = true;
  programs.gnupg.agent.enable = true;
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

  #Games
  nixpkgs.config.allowUnfree = true;
  programs.steam.enable = true;


  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Firewall.
  #networking.firewall.allowedTCPPorts = [ 51413 38692 15441 ];
  #networking.firewall.allowedUDPPorts = [ 51413 38692 15441 ];
  networking.firewall.enable = true;

  # Enable CUPS to print documents.
  #services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.opengl = {
    enable = true;
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
