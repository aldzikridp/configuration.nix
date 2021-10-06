{ pkgs, vimUtils, fetchgit }:

with vimUtils;

let
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
in
{
  "tokyonight" = buildVimPlugin {
    name = "tokyonight";
    src = fetchgit {
      url = "https://github.com/folke/tokyonight.nvim";
      rev = "eede574f9ef57137e6d7e4bab37b09db636c5a56";
      sha256 = "06hhg5n8k9iri3mlgbf80hwz9qwjkvvl6x5f6kjih7klzcx6x04j";
    };
    dependencies = [ ];
  };

  cmp-nvim-lsp = buildVimPlugin {
    name = "cmp-nvim-lsp";
    src = fetchgit {
      url = "https://github.com/hrsh7th/cmp-nvim-lsp";
      rev = "899f70af0786d4100fb29987b9ab03eac7eedd6a";
      sha256 = "1gw478b77smkn3k42h2q3ddq2kcd7vm6mnmjmksvbsfv5xp9pln0";
    };
  };

 cmp_luasnip = buildVimPlugin {
    name = "cmp_luasnip";
    src = fetchgit {
      url = "https://github.com/saadparwaiz1/cmp_luasnip/";
      rev = "fc033ce441b29f1755fd2314125772d21e5c5127";
      sha256 = "1np6x7wybh7w1m06h03sczv35a7ag3j37a8sk0yjcm95vysmwikd";
    };
  };

  nvim-cmp = buildVimPlugin {
    name = "nvim-cmp";
    src = fetchgit {
      url = "https://github.com/hrsh7th/nvim-cmp/";
      rev = "f3a54918944d2c8778e6f13e2fc3ec4251863afb";
      sha256 = "0zjmvpxx46dy1q7jg1a7r51nqc7wzqa8vjzd8ff8nphs0j5zlvfn";
    };
  };


  #"DyeVim" = buildVimPlugin {
  #  name = "DyeVim";
  #  src = fetchgit {
  #    url = "https://github.com/davits/DyeVim.git";
  #    rev = "b915e4ddc3d9b4b5365ce264ce1e7c1b13281915";
  #    sha256 = "0s35l13qdr1hkc3yxrrj8x13fp7rj97qqibmd103dsilz4jspdif";
  #  };
  #  dependencies = [ pkgs.vimPlugins.YouCompleteMe ];
  #};

  #"color_coded" = buildVimPlugin {
  #  name = "color_coded";
  #  src = fetchgit {
  #    url = "https://github.com/jeaye/color_coded.git";
  #    rev = "16e71d6f5850849c6ffc9a06a7c952e27d351866";
  #    sha256 = "0cvh9r4j8177z3sqvbk15dylj76r3qfz1z5qhar3rg42b7hhir5l";
  #  };
  #  dependencies = [ pkgs.llvm pkgs.llvmPackages.clang-unwrapped pkgs.ncurses pkgs.zlib pkgs.xz pkgs.lua ];
  #};
}
