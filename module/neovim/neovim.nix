with import <nixpkgs> { };

let
  plugins = pkgs.callPackage ./plugin.nix { };
in
neovim.override {
  configure = {
    packages.myVimPackage = with pkgs.vimPlugins; {
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
        nvim-bufferline-lua
        plugins.tokyonight
      ];
      opt = [
        nvim-jdtls
      ];
    };
  };
}
