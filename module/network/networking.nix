{ config, ... }:
{
  networking.hostName = "EVA-01"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Firewall.
  #networking.firewall.allowedTCPPorts = [ 51413 38692 15441 ];
  #networking.firewall.allowedUDPPorts = [ 51413 38692 15441 ];
  networking.firewall.allowedTCPPorts = [ 51413 ];
  networking.firewall.allowedUDPPorts = [ 51413 ];
  networking.firewall.enable = true;
}
