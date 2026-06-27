{ config, pkgs, lib, myUsername, ... }:

{
  nix = {
    package = pkgs.nixVersions.stable; # or versioned attributes like nixVersions.nix_2_8
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };
  nix = {
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  imports =
    [
      ./module/systemd-boot/boot.nix
      #./module/bash
      ./module/network/networking.nix
      ./module/network/dnscrypt.nix
      ./module/network/dnsmasq-adblock
      ./module/polkit
      #./module/neovim/neovim.nix
      #./module/mpv/mpv.nix
      #./module/sway/sway.nix
      ./module/fonts/fonts.nix
      #./module/firefox
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.earlyoom.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #steam-run-native
    #(ncmpcpp.override { visualizerSupport = true; })
    #_7zz
    dnsutils
    inetutils
    gcc
    git
    gnumake
    killall
    man-pages
    man-pages-posix

    #mpc_cli
    #mpd
    ncdu

    ### File Manager ###
    file
    atool             # archive preview
    xdg-utils
    #(pkgs.callPackage ./pkgs/rifle/default.nix { })
    #(pkgs.callPackage ./pkgs/ctpv/default.nix { })
    #ctpv
    ###################
    
    #starship
    #(transmission_4.override { enableCli = false; })
  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  #Games
  #nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-runtime"
    "steam-run"
    "corefonts"
  ];


  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;


  # Enable CUPS to print documents.
  #services.printing.enable = true;

  # Enable sound.
  #sound.enable = true;
  #hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  services.pipewire.wireplumber.enable = true;
  
  services.udisks2.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config = {
      common = {
        default = "gtk";
        "org.freedesktop.impl.portal.Screenshot" = "wlr";
        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      };
    };
  };

  security.pam.services.swaylock = {};

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
  #hardware.opengl.package = pkgs.old.mesa.drivers;

   users.users.${myUsername} = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel" 
      #"docker" 
      "podman"
      "video" 
      "audio" 
      "networkmanager"
    ];
    #Generate hashed password with "mkpasswd -m sha-512"
    hashedPassword = "$6$WoF9RxiLei5iC5zp$UyckvU7P3yhaptLOKyPohWkXNcfd7UuQEWif5jjyOVRcz7qiPv3B47ap4LV5OChS8QeV1xehzYJMk.mI7S2rf0";
  };
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  documentation.dev.enable = true;

  services = {
    syncthing = {
        enable = true;
        user = myUsername;
        dataDir = "/home/${myUsername}/Syncthing/Data";    # Default folder for new synced folders
        configDir = "/home/${myUsername}/Syncthing/.config/";   # Folder for Syncthing's settings and keys
    };
    suwayomi-server = {
      enable = true;
      openFirewall = true;
      package = pkgs.suwayomi-server.overrideAttrs (oldAttrs: {
        version = "2.2.2100";
        src = pkgs.fetchurl {
          url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v2.2.2100/suwayomi-server-v2.2.2100.jar";
          sha256 = "0pph649vf3mf98dbqkzz8y881g81mbwxrnwg1jdrb6zs7fj3509w";
        };
      });
      settings = {
        server = {
          extensionRepos = [
            "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"
            "https://raw.githubusercontent.com/yuzono/manga-repo/repo/index.min.json"
            "https://raw.githubusercontent.com/yuzono/cursed-manga-repo/repo/index.min.json"
          ];
          excludeUnreadChapters = false;
          excludeNotStarted = false;
          excludeCompleted = false;
          updateMangas = true;
        };
      };
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "23.05"; # Did you read the comment?

}
