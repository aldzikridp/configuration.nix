{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    nixpkgs-old.url = github:NixOS/nixpkgs/nixos-21.11;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-old, ... }:
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
      overlay-old = final: prev: {
        old = nixpkgs-old.legacyPackages.${prev.system};
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
            ./configuration.nix
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
                overlay-old
                (self: super: { mesa = pkgs.old.mesa;})
                (self: super: { wlroots = pkgs.old.wlroots;})
                (self: super: { sway-unwrapped = pkgs.old.sway-unwrapped;})
              ];
            })
            ./configuration.nix
            ./module/eva02-hardware-configuration.nix
            ./module/games
          ];
        };
      };
    };
}
