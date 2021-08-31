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
          bufferline-nvim
          cmp-buffer
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-path
          cmp_luasnip
          lspsaga-nvim
          lualine-nvim
          luasnip
          nvim-cmp
          nvim-colorizer-lua
          nvim-lspconfig
          nvim-tree-lua
          nvim-treesitter
          nvim-web-devicons
          plugins.tokyonight
          popup-nvim
          telescope-fzy-native-nvim
          telescope-nvim
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
