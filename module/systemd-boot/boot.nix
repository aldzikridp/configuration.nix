let 
 secrets = import ../../secrets/secrets.nix;
in {
# Use the systemd-boot EFI boot loader.
  imports =
  [
    ./systemd-boot.nix
  ];
  boot = {
    cleanTmpDir = true;
    loader = {
      systemd-boot = {
        enable = true;
        signed = true;
        signing-key = secrets.secure-boot.key;
        signing-certificate = secrets.secure-boot.cert;
        configurationLimit = 4;
      };
      efi.canTouchEfiVariables = true;
    };
    #supportedFilesystems = [ "ntfs" ];
  };
}
