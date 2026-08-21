{ lib
, fetchurl
, appimageTools
, makeWrapper
}:

let
  version = "3.8.49";

  src = fetchurl {
    url = "https://github.com/diegosouzapw/OmniRoute/releases/download/v${version}/OmniRoute-${version}.AppImage";
    hash = "sha256-ywswXBjkIRcq9f/thp4M3+7gXY+0Zeel1mYLSNgSLyc=";
  };

  appimageContents = appimageTools.extractType2 {
    pname = "omniroute";
    inherit version src;
  };
in
appimageTools.wrapType2 {
  pname = "omniroute";
  inherit version src;

  extraInstallCommands = ''
    # Install desktop file and icon
    mkdir -p $out/share/applications
    cp ${appimageContents}/omniroute.desktop $out/share/applications/ 2>/dev/null || true
    mkdir -p $out/share/icons
    cp ${appimageContents}/omniroute.png $out/share/icons/ 2>/dev/null || true

    # Fix desktop file Exec line
    substituteInPlace $out/share/applications/omniroute.desktop \
      --replace 'Exec=AppRun' 'Exec=omniroute' 2>/dev/null || true
  '';

  meta = with lib; {
    description = "Free MIT AI gateway: one endpoint, 340+ providers, 1200+ models — works with Claude Code, Codex, Cursor, Copilot";
    homepage = "https://github.com/diegosouzapw/OmniRoute";
    license = licenses.mit;
    mainProgram = "omniroute";
    platforms = [ "x86_64-linux" ];
  };
}
