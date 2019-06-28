# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./thinkpad.nix
    ];

  # Use the systemd-boot EFI boot loader.
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;

   networking.hostName = "EVA-01"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
   networking.networkmanager.enable  = true;

  # Enable dnscrypt client
   services.dnscrypt-proxy = {
    enable = true;
    # the official default resolver is unreliable from time to time
    # either use a different, trust-worthy one from here:
    #   https://github.com/jedisct1/dnscrypt-proxy/blob/master/dnscrypt-resolvers.csv 
    # or setup your own.
    resolverName = "d0wn-lv-ns1";
    };
    networking.nameservers = ["127.0.0.1"];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
   time.timeZone = "Asia/Jakarta";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [
      wget git neovim gnupg  
    ];
   
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
   programs.zsh.enable = true;
   programs.gnupg.agent.enable = true;

  users.extraUsers.master-x = {
    shell = pkgs.zsh;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
   networking.firewall.allowedTCPPorts = [ 51413 ];
   networking.firewall.allowedUDPPorts = [ 51413 ];
  # Or disable the firewall altogether.
   networking.firewall.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable VAAPI.
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
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
    services.xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
      };

      desktopManager.gnome3 = {
        enable = true;
      };
    };  

    environment.gnome3.excludePackages = [
      pkgs.gnome3.gnome-software
      pkgs.gnome3.gnome-usage
      pkgs.gnome3.epiphany
      pkgs.gnome3.accerciser
      pkgs.gnome3.gnome-packagekit
      pkgs.gnome3.totem
      pkgs.gnome3.totem-pl-parser
      pkgs.gnome3.gnome-music
      pkgs.gnome3.evolution
      pkgs.gnome3.gnome-weather
    ];
 
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.master-x = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
