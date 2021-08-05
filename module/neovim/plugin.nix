{ pkgs, vimUtils, fetchgit }:

with vimUtils;

let
  buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
in
{
  "tokyonight" = buildVimPlugin {
    name = "tokyonight";
    src = fetchgit {
      url = "https://github.com/folke/tokyonight.nvim";
      rev = "0ee0bcf14d8c7c70081a0e9967c211121c4300c7";
      sha256 = "0rkw544dzgyp76ag3zrh8d3n0mri5c0cjpy8mvbfpgyj87w18m8d";
    };
    dependencies = [ ];
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
