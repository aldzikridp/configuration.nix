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
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # use this variant if unfree packages are needed:
        # unstable = import nixpkgs-unstable {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
      };
      overlay-old = final: prev: {
        old = nixpkgs-old.legacyPackages.${prev.system};
      };
    in
    {
      nixosConfigurations = {
        EVA-02 = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                overlay-unstable
                overlay-old
                (self: super: {
                  mesa = super.mesa.overrideAttrs (old: {
                    version = "22.1.1";
                    src = super.fetchurl {
                      urls = [
                        "https://mesa.freedesktop.org/archive/mesa-22.1.1.tar.xz"
                      ];
                      sha256 =  "1w8fpki67238l4yc92hsnsh4402py9zspirbmirxp577zxjhi526";
                    };
                  });
                })
              ];
            })
            ./configuration.nix
          ];
        };
      };
    };
}
