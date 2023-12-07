{ lib
, pkgs
, fetchFromGitHub
, ... }:

pkgs.stdenv.mkDerivation rec {
  name = "ctpv";
  src = fetchFromGitHub {
    owner = "NikitaIvanovV";
    repo = "ctpv";
    rev = "bfed2488ad5186b27782f06248dc5a59208701af";
    sha256 = "sha256-CFCEJfCSn/GCK2kcD7KUkCq8O++BbAyhCDk3CZo/koA=";
    #sha256 = lib.fakeSha256;
  };
  # libmagic libcrypto
  nativeBuildInputs = with pkgs; [ file openssl ];
  installPhase = "DESTDIR=$out make PREFIX=\"\" install";
}
