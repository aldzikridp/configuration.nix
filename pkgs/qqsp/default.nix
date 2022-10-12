{ lib
, mkDerivation
, stdenv
, fetchFromGitLab
, qtbase
, qtwayland
, wayland
, qtwebengine
, qtmultimedia
, qmake
}:

mkDerivation rec {
  pname = "qqsp";
  version = "1.9";

  src = fetchFromGitLab {
    owner  = "Sonnix1";
    repo   = "Qqsp";
    rev    = "v${version}";
    hash   = "sha256-eDgoa+/dcJ8Ti+YLHgKUKus0+zRrFEuJ19wUpbFpcBU=";
  };

  nativeBuildInputs = [ qmake ];
  buildInputs = [ qtbase qtwayland wayland qtwebengine qtmultimedia];

  installPhase = ''
    mkdir -p $out/bin
    cp Qqsp $out/bin
  '';

  meta = with lib; {
    description = "Qt Quest Soft Player";
    homepage    = "https://gitlab.com/Sonnix1/Qqsp";
    license     = licenses.mit;
  };
}
