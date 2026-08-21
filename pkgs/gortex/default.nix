{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
}:

let
  version = "0.63.8";

  src = fetchurl {
    url = "https://github.com/zzet/gortex/releases/download/v${version}/gortex_linux_amd64.tar.gz";
    hash = "sha256-6dcotr3HuDFk8GMxj27wftI34/LEpTF4whZDSuvzc0M=";
  };
in
stdenv.mkDerivation {
  pname = "gortex";
  inherit version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  dontBuild = true;
  dontConfigure = true;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp gortex $out/bin/gortex
    chmod +x $out/bin/gortex

    runHook postInstall
  '';

  meta = with lib; {
    description = "High-performance code-intelligence engine for AI agents and IDE, supports 257 languages, multi repositories, based on graph";
    homepage = "https://github.com/zzet/gortex";
    license = licenses.asl20;
    mainProgram = "gortex";
    platforms = [ "x86_64-linux" ];
  };
}
