{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, ... }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        #unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # use this variant if unfree packages are needed:
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        EVA-01 = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ({networking.hostName = "EVA-01";})
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-unstable
              ];
            })
            ./module/virtualisation
            ./configuration.nix
            #(nixpkgs + "/nixos/modules/profiles/hardened.nix")
            ./module/thinkpad.nix
            ./module/eva01-hardware-configuration.nix
          ];
          
        };
        EVA-02 = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ({networking.hostName = "EVA-02";})
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-unstable
              ];
            })
            ./module/virtualisation
            ./configuration.nix
            #(nixpkgs + "/nixos/modules/profiles/hardened.nix")
            ./module/eva02-hardware-configuration.nix
            ./module/gns3
            #./module/games
          ];
        };
      };
    };
}
