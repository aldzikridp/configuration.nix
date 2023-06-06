let
  secrets = import ../../secrets/secrets.nix;
in
{
  # Use the systemd-boot EFI boot loader.
  imports =
    [
      ./systemd-boot.nix
    ];
  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      timeout = 2;
      systemd-boot = {
        enable = true;
        configurationLimit = 4;
        secureBoot = {
          enable = true;
          keyPath = "/DB.key";
          certPath = "/DB.crt";
        };
      };
      efi.canTouchEfiVariables = true;
    };
    #supportedFilesystems = [ "ntfs" ];
  };
}
