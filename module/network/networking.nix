{ config, ... }:
{
  networking.networkmanager.enable = true;

  # Firewall.
  #networking.firewall.allowedTCPPorts = [ 51413 38692 15441 ];
  #networking.firewall.allowedUDPPorts = [ 51413 38692 15441 ];
  networking.firewall.allowedTCPPorts = [
    51413 # transmission
    22000 # syncthing
  ];
  networking.firewall.allowedUDPPorts = [
    51413 # transmission
    22000 # syncthing
    21027 # syncthing
  ];
  networking.firewall.enable = true;
}
