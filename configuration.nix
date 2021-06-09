# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
    (self: super: {
    mpv = super.mpv-with-scripts.override {
      scripts = [ self.mpvScripts.thumbnail self.mpvScripts.thumbnail ];
    };
    })
  ];

  imports =
    [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    #/etc/nixos/hardware-configuration.nix
    ./module/systemd-boot/systemd-boot.nix
    ];

  # Use the systemd-boot EFI boot loader.
   #boot.loader.systemd-boot.enable = true;
   #boot.loader.efi.canTouchEfiVariables = true;
   #boot.loader.systemd-boot.configurationLimit = 4;
   #boot.supportedFilesystems = [ "ntfs" ];
   boot = {
    loader = {
     systemd-boot = {
      enable = true;
      signed = true;
      signing-key = "/home/master-x/boot-key/DB.key";
      signing-certificate = "/home/master-x/boot-key/DB.crt";
      configurationLimit = 4;
     };
     efi.canTouchEfiVariables = true;
    };
    #supportedFilesystems = [ "ntfs" ];
   };

   networking.hostName = "EVA-02"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
   networking.networkmanager.enable  = true;

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

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
    };
  };

  #systemd.services.dnscrypt-proxy2.serviceConfig = {
  #  StateDirectory = "dnscrypt-proxy2";
  #};

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

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
     imagemagick
     imv
     jq
     keepassxc
     mpv
     neovim-nightly
     p7zip
     pavucontrol
     polkit_gnome
     ranger
     ripgrep
     rsync
     slurp
     starship
     wf-recorder
     wget 
     zathura
     #libva-utils #for VAAPI
    ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  # programs.zsh.enable = true;
   programs.gnupg.agent.enable = true;
   programs.sway = {
   enable = true;
   wrapperFeatures.gtk = true; # so that gtk works properly
   extraPackages = with pkgs; [
     swaylock
     swayidle
     wl-clipboard
     grim
     mako # notification daemon
     kitty # Alacritty is the default terminal in the config
     wofi # Dmenu is the default in the config but i recommend wofi since its wayland native
     waybar
     xwayland
   ];
 };
  nixpkgs.config.pulseaudio = true;


  #users.extraUsers.master-x = {
  #  shell = pkgs.zsh;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
   #networking.firewall.allowedTCPPorts = [ 51413 38692 15441 ];
   #networking.firewall.allowedUDPPorts = [ 51413 38692 15441 ];
  # Or disable the firewall altogether.
   networking.firewall.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable VAAPI.
  #nixpkgs.config.packageOverrides = pkgs: {
  #  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  #};
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
      #vaapi-intel-hybrid
      #vaapiIntel
      #intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
    ];
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  
  # Enable the Gnome Desktop Environment.
  #  services.xserver = {
  #    enable = true;

  #    displayManager.gdm = {
  #      enable = true;
  #    };

  #    desktopManager.gnome3 = {
  #      enable = true;
  #    };
  #  };  

  #  environment.gnome3.excludePackages = [
  #    pkgs.gnome3.gnome-software
  #    pkgs.gnome3.gnome-usage
  #    pkgs.gnome3.epiphany
  #    pkgs.gnome3.accerciser
  #    pkgs.gnome3.gnome-packagekit
  #    pkgs.gnome3.totem
  #    pkgs.gnome3.totem-pl-parser
  #    pkgs.gnome3.gnome-music
  #    pkgs.gnome3.evolution
  #    pkgs.gnome3.gnome-weather
  #    pkgs.gnome3.vinagre
  #    pkgs.gnome3.gnome-todo
  #    pkgs.gnome3.simple-scan
  #  ];
 
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.master-x = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "audio" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.09"; # Did you read the comment?

}
