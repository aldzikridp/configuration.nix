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
          keyPath = secrets.secure-boot.key;
          certPath = secrets.secure-boot.cert;
        };
      };
      #efi.canTouchEfiVariables = true;
    };
    #supportedFilesystems = [ "ntfs" ];
  };
}
