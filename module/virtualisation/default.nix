{ config, pkgs, ... }:
let
  myquickemu = pkgs.quickemu.override (quickemuOld: {
    spice-gtk = quickemuOld.spice-gtk.overrideAttrs (attrs: {
      buildInputs = attrs.buildInputs ++ [
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
      ];
    });
  });
in
{
  # Enable docker service
  virtualisation.docker.enable = true;
  # rootless docker
  #virtualisation.docker.rootless = {
  #  enable = true;
  #  setSocketVariable = true;
  #};
  #virtualisation.podman = {
  #  enable = true;
  #  dockerCompat = true;
  #  defaultNetwork.settings = {
  #    dns_enabled = true;
  #  };
  #};

  # Virt-manager
  #virtualisation.libvirtd.enable = true;
  #virtualisation.libvirtd.qemu.runAsRoot = false;
  #programs.dconf.enable = true;
  #environment.systemPackages = with pkgs; [ virt-manager ];
  #users.users.master-x.extraGroups = [ "libvirtd" ];
  #virtualisation.podman.enable = true;
  #services.dnsmasq.extraConfig = ''
  #  interface=lo
  #  interface=enp8s0
  #  bind-interfaces
  #'';

  # Quickemu
  environment.systemPackages = with pkgs; [ 
    myquickemu
    samba
    fuse-overlayfs # for minikube with podman driver
  ];
}
