{ config, pkgs, ... }:
with import <nixpkgs> { };
let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  #plugins = pkgs.callPackage ./plugin.nix { };
  buildVimPlugin = unstable.pkgs.vimUtils.buildVimPlugin;
  "fzf-lua" = buildVimPlugin {
    name = "fzf-lua";
    src = pkgs.fetchFromGitHub {
      owner = "ibhagwan";
      repo = "fzf-lua";
      rev = "58320a257957e4083f866cc6458b04a72493df33";
      sha256 = "02i4w8afdys5idm7fvxfp8fimbinp9nca9kyf3r90w2769an0q4j";
    };
  };
  "filetype-nvim" = buildVimPlugin {
    name = "filetype-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "nathom";
      repo = "filetype.nvim";
      rev = "25b5f7e5314d5e7739be726860253c67f7e513bf";
      sha256 = "1qjzmcyq9dl4rqb8yijbqsk4d7vpchhj3268b0vnxbd547fc6cjj";
    };
  };
  myneovim = unstable.neovim.override {
    configure = {
      customRC = ''
        source /home/master-x/.config/nvim/init.lua
      '';
      packages.myVimPackage = with unstable.pkgs.vimPlugins; {
        start = [
          bufferline-nvim
          cmp-buffer
          cmp-cmdline
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-path
          cmp_luasnip
          filetype-nvim
          friendly-snippets
          fzf-lua
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
          #telescope-fzf-native-nvim
          #telescope-nvim
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
