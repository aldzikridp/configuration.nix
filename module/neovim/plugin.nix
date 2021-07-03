{ pkgs, vimUtils, fetchgit }:

with vimUtils;

let
  buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
  #yarn2nix = pkgs.callPackage
  #  (pkgs.fetchFromGitHub {
  #    owner = "moretea";
  #    repo = "yarn2nix";
  #    rev = "780e33a07fd821e09ab5b05223ddb4ca15ac663f";
  #    sha256 = "1f83cr9qgk95g3571ps644rvgfzv2i4i7532q8pg405s4q5ada3h";
  #  })
  #  { };
in
{
  "tokyonight" = buildVimPlugin {
    name = "tokyonight";
    src = fetchgit {
      url = "https://github.com/folke/tokyonight.nvim";
      rev = "852c9a846808a47d6ff922fcdbebc5dbaf69bb56";
      sha256 = "1fkp03kycwp73i1k2jmxm0m3zipbxwa8lrb5shzfwcdcn6a3cwja";
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
