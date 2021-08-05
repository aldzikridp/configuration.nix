{ config, ... }:
{
  networking.hostName = "EVA-02"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Firewall.
  #networking.firewall.allowedTCPPorts = [ 51413 38692 15441 ];
  #networking.firewall.allowedUDPPorts = [ 51413 38692 15441 ];
  networking.firewall.enable = true;
}
