{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    <nixpkgs-unstable>
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  #plugins = pkgs.callPackage ./plugin.nix { };
  buildVimPlugin = unstable.pkgs.vimUtils.buildVimPlugin;
  #"filetype-nvim" = buildVimPlugin {
  #  name = "filetype-nvim";
  #  src = fetchgit {
  #    url = "https://github.com/nathom/filetype.nvim/";
  #    rev = "c4d86b2748fda2c6bd6dfc47e75c727cf50afbb8";
  #    sha256 = "14qx4bssifi29525i3g7ik0xaldj9d29d1cl439k2d4qxzn5zzmp";
  #  };
  #  dependencies = [ ];
  #};
  myneovim = unstable.neovim.override {
    configure = {
      customRC = ''
        source /home/master-x/.config/nvim/init.lua
      '';
      packages.myVimPackage = with unstable.pkgs.vimPlugins; {
        start = [
          bufferline-nvim
          cmp-buffer
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-path
          cmp_luasnip
          friendly-snippets
          lualine-nvim
          luasnip
          indent-blankline-nvim
          null-ls-nvim
          nvim-cmp
          #nvim-colorizer-lua
          nvim-lspconfig
          nvim-lsp-ts-utils
          nvim-tree-lua
          nvim-treesitter-refactor
          nvim-treesitter-textobjects
          nvim-web-devicons
          telescope-fzf-native-nvim
          telescope-nvim
          tokyonight-nvim
          (nvim-treesitter.withPlugins (
            plugins: unstable.pkgs.tree-sitter.allGrammars
          ))
        ];
        #opt = [
        #  nvim-jdtls
        #];
      };
    };
  };
in
{
  environment.systemPackages = with pkgs; [
    myneovim
  ];
}
