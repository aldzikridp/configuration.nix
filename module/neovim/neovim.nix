{ pkgs, ... }:
let
  plugins = pkgs.callPackage ./plugin.nix { };
  #buildVimPlugin = unstable.pkgs.vimUtils.buildVimPlugin;
  #"filetype-nvim" = buildVimPlugin {
  #  name = "filetype-nvim";
  #  src = pkgs.fetchFromGitHub {
  #    owner = "nathom";
  #    repo = "filetype.nvim";
  #    rev = "b522628a45a17d58fc0073ffd64f9dc9530a8027";
  #    sha256 = "0l2cg7r78qbsbc6n5cvwl5m5lrzyfvazs5z3gf54hspw120nzr87";
  #  };
  #};
  myPluginList = with pkgs.unstable.pkgs.vimPlugins;[          
          bufferline-nvim
          cmp-buffer
          cmp-cmdline
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-path
          cmp_luasnip
          friendly-snippets
          fzf-lua
          lualine-nvim
          luasnip
          indent-blankline-nvim
          nvim-cmp
          nvim-lspconfig
          nvim-tree-lua
          nvim-treesitter-refactor
          nvim-treesitter-textobjects
          nvim-web-devicons
          plenary-nvim
          tokyonight-nvim
          nvim-treesitter.withAllGrammars
          gitsigns-nvim
  ];
  myOtherPluginList = with plugins;[
    kulala_nvim
    #curl_nvim
  ];
  myneovim = pkgs.unstable.pkgs.neovim.override {
    configure = {
      customRC = ''
        source $HOME/.config/nvim/init.lua
      '';
      packages.myVimPackage = {
        start = [
          myPluginList
          myOtherPluginList
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
    neovim-remote
    myneovim
  ];
  programs.neovim = {
    enable = false;
    configure = {
      customRC = ''
        source $HOME/.config/nvim/init.lua
      '';
      packages.myVimPackage = {
        start = [
          myPluginList
          myOtherPluginList
        ];
        #opt = [
        #  nvim-jdtls
        #];
      };
    };
  };
}
