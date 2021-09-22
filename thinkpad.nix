{ config, lib, pkgs, ... }:
{
  services = {
    tlp = {
      enable = true;
      settings = {
        SATA_LINKPWR_ON_BAT="max_performance";
        START_CHARGE_THRESH_BAT0=31;
        STOP_CHARGE_THRESH_BAT0=81;
        DEVICES_TO_DISABLE_ON_STARTUP="bluetooth";
    };
   # xserver.xkbModel = "thinkpad60";
   tcsd = {
       enable = true;
   };
  };
};

  boot = {
    kernelModules = [ 
      "thinkpad_acpi" 
      "acpi_call" 
    ];
    extraModulePackages = with config.boot.kernelPackages; [ 
      acpi_call 
    ];
  };

  # Enable VAAPI.
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  environment.systemPackages = with pkgs; [
    trousers
  ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapi-intel-hybrid
      vaapiIntel
      intel-media-driver
    ];
  };
}
