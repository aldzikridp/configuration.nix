{ lib, mkDerivation, callPackage, fetchurl,
  guile_1_8, qtbase, xmodmap, which, freetype,
  libjpeg,
  sqlite,
  tex ? null,
  aspell ? null,
  git ? null,
  python3 ? null,
  cmake,
  pkg-config,
  wrapQtAppsHook,
  wayland,
  ghostscriptX ? null,
  extraFonts ? false,
  chineseFonts ? false,
  japaneseFonts ? false,
  koreanFonts ? false }:

let
  pname = "TeXmacs";
  version = "2.1.2";
  common = callPackage ./common.nix {
    inherit tex extraFonts chineseFonts japaneseFonts koreanFonts;
  };
in
mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/aldzikridp/texmacs/archive/17a04a54da17f062961c0e694705b742233ad8de.tar.gz";
    sha256 = "1b218qlvxjcwjcbnlp0fbxi4jpcabbrb2h7x27cj0hb0p9ry3lwb";
  };

  nativeBuildInputs = [ cmake pkg-config wrapQtAppsHook ];
  buildInputs = [
    guile_1_8
    qtbase
    ghostscriptX
    freetype
    libjpeg
    sqlite
    git
    python3
    wayland
  ];
  NIX_LDFLAGS = "-lz";

  qtWrapperArgs = [
    "--suffix" "PATH" ":" (lib.makeBinPath [
      xmodmap
      which
      ghostscriptX
      aspell
      tex
      git
      python3
      wayland
    ])
  ];

  postFixup = ''
    wrapQtApp $out/bin/texmacs
  '';

  inherit (common) postPatch;

  meta = common.meta // {
    maintainers = [ lib.maintainers.roconnor ];
    platforms = lib.platforms.gnu ++ lib.platforms.linux;  # arbitrary choice
  };
}
