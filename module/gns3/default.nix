{ config, pkgs, ... }@inputs:
{
  environment.systemPackages = with pkgs; [
    unstable.gns3-server
    unstable.gns3-gui
    unstable.vpcs
    unstable.ubridge
    unstable.dynamips
    unstable.iouyap
    qemu
  ];

  ## libvirtd needed for cloud in GNS3
  #virtualisation.libvirtd.enable = true;
  #virtualisation.libvirtd.qemu.runAsRoot = false;
  #programs.dconf.enable = true;
  #users.users.master-x.extraGroups = [ "libvirtd" ];

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
