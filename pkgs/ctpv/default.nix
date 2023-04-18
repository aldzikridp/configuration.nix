{ lib
, pkgs
, fetchFromGitHub
, ... }:

pkgs.stdenv.mkDerivation rec {
  name = "ctpv";
  src = fetchFromGitHub {
    owner = "NikitaIvanovV";
    repo = "ctpv";
    rev = "930535cbea1af0edfe918d4704aa13728e735845";
    sha256 = "0fhwcs58sn14mjm37kck154pyq2bsckhfzg1px87rlq7m0zjcg6m";
  };
  # libmagic libcrypto
  nativeBuildInputs = with pkgs; [ file openssl ];
  installPhase = "DESTDIR=$out make PREFIX=\"\" install";
}
