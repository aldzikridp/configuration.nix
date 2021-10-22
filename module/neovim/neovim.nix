{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/archive/39f0cfdd12119d991225c6ab2d7e4483d67cf0a3.tar.gz)
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
          nvim-cmp
          nvim-colorizer-lua
          nvim-lspconfig
          nvim-tree-lua
          nvim-web-devicons
          telescope-fzf-native-nvim
          telescope-nvim
          tokyonight-nvim
          (nvim-treesitter.withPlugins (
              plugins: unstable.pkgs.tree-sitter.allGrammars
          ))
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
