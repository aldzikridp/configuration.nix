{ pkgs, vimUtils, fetchFromGitHub }:


let
  buildVimPlugin = pkgs.unstable.pkgs.vimUtils.buildVimPlugin;
in
{
  "kulala_nvim" = buildVimPlugin {
    name = "kulala_nvim";
    src = fetchFromGitHub {
      owner = "mistweaverco";
      repo = "kulala.nvim";
      rev = "v2.7.0";
      hash = "sha256-GFaTFQ0jPvyJgkG83+HAeZqTzr7CMIHDJ8q9V6ljdS8=";
    };
  };

  "curl_nvim" = buildVimPlugin {
    name = "curl_nvim";
    src = fetchFromGitHub {
      owner = "oysandvik94";
      repo = "curl.nvim";
      rev = "cafd091aabfa531a6f7a0631f2e6d22cff4b8c91";
      hash = "sha256-O+zIvD2jMg2VOFBTetCYriB4kZKGWQ8paqkIPGpkkW4=";
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
