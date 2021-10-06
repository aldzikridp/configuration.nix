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
      ./module/network/networking.nix
      ./module/network/dnscrypt.nix
      ./module/pass/pass.nix
      ./module/neovim/neovim.nix
      ./module/sway/sway.nix
    ];



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
    gcc
    fd
    ffmpeg
    fzf
    git
    htop
    imagemagick
    keepassxc
    mpv
    p7zip
    ranger
    rclone
    ripgrep
    rsync
    rnix-lsp
    starship
    steam-run-native
    wget
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
  nixpkgs.config.allowUnfree = true;
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
