{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gns3-server
    gns3-gui
    vpcs
    ubridge
    dynamips
  ];
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.runAsRoot = false;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager qemu ];
  users.users.master-x.extraGroups = [ "libvirtd" ];

  ## Modify .config/GNS3/2.2/gns3_server.config
  ## then change ubridge_path to /run/current-system/sw/bin/ubridge
  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin+eip cap_net_raw+eip cap_net_broadcast+eip cap_net_bind_service+eip";
    owner = "nobody";
    group = "nogroup";
    #permissions = "u+rx,g+x";
  };
}
