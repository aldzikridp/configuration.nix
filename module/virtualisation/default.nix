{ config, pkgs, ... }:
{
  # Enable docker service
  #virtualisation.docker.enable = true;

  # Virt-manager
  #virtualisation.libvirtd.enable = true;
  #programs.dconf.enable = true;
  #environment.systemPackages = with pkgs; [ virt-manager ];
  #users.users.master-x.extraGroups = [ "libvirtd" ];
  #services.dnsmasq.extraConfig = ''
  #  interface=lo
  #  interface=enp8s0
  #  bind-interfaces
  #'';
}
