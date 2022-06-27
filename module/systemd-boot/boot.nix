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
    cleanTmpDir = true;
    loader = {
      timeout = 2;
      systemd-boot = {
        enable = true;
        configurationLimit = 4;
        secureBoot = {
          enable = true;
          keyPath = "/home/master-x/configuration.nix/secrets/boot-key/DB.key";
          certPath = "/home/master-x/configuration.nix/secrets/boot-key/DB.crt";
        };
      };
      #efi.canTouchEfiVariables = true;
    };
    #supportedFilesystems = [ "ntfs" ];
  };
}
