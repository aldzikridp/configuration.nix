{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gns3-server
    gns3-gui
    vpcs
    dynamips
    qemu
  ];

  ## libvirtd needed for cloud in GNS3
  #virtualisation.libvirtd.enable = true;
  #virtualisation.libvirtd.qemu.runAsRoot = false;
  #programs.dconf.enable = true;
  users.users.master-x.extraGroups = [ "libvirtd" ];

  ## Modify .config/GNS3/2.2/gns3_server.config
  ## then change ubridge_path to /run/wrappers/bin/ubridge
  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin+eip cap_net_raw+eip";
    owner = "master-x";
    group = "users";
    permissions = "u+rx,g+x";
  };
}
