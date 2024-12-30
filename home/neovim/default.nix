{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    #extraConfig = ''
    #  source $HOME/.config/nvim/myinit.lua
    #'';
    plugins = with pkgs.vimPlugins;[
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
      rest-nvim
    ];
  };
}
