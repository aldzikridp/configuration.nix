{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/archive/master.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  plugins = pkgs.callPackage ./plugin.nix { };
  myneovim = unstable.neovim.override {
    configure = {
      packages.myVimPackage = with unstable.pkgs.vimPlugins; {
        start = [
          nvim-lspconfig
          nvim-tree-lua
          nvim-treesitter
          popup-nvim
          telescope-nvim
          telescope-fzy-native-nvim
          lspsaga-nvim
          nvim-compe
          nvim-web-devicons
          nvim-colorizer-lua
          lualine-nvim
          bufferline-nvim
          plugins.tokyonight
        ];
        opt = [
          nvim-jdtls
        ];
      };
    };
  };
in
{
  environment.systemPackages = with pkgs; [
   myneovim
  ];
}
