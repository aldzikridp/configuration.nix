{ stdenv
, pkgs
, lib
, fetchurl
, intltool
, pkg-config
, networkmanager
, libreswan
, gtk3
, gtk4
, file
, libnl
, gnome
, libsecret
, libnma
, libnma-gtk4
, fetchFromGitHub
, substituteAll
}:

stdenv.mkDerivation rec {
  pname = "NetworkManager-libreswan";
  version = "1.6.0";

  src = fetchurl {
    url = "https://download.gnome.org/sources/NetworkManager-libreswan/1.2/NetworkManager-libreswan-1.2.16.tar.xz";
    hash = "sha256-xrfvcfZYfZwJ437ObCC0xKVFb4DJDlyetuyJ6Ow45lQ=";
  };

  patches = [
    (substituteAll {
      src = ./fix-paths.patch;
      inherit libreswan;
    })
  ];

  nativeBuildInputs = [
    intltool
    pkg-config
    file
    libnl
  ];

  buildInputs = [
    libnl
    networkmanager
    libreswan
    libsecret
    gtk3
    gtk4
    libnma
    libnma-gtk4
  ];

  configureFlags = [
    "--disable-more-warnings" # disables -Werror
    "--with-gtk4"
    "--enable-absolute-paths"
  ];

  PKG_CONFIG_LIBNM_VPNSERVICEDIR = "${placeholder "out"}/lib/NetworkManager/VPN";

  passthru = {
    networkManagerPlugin = "VPN/nm-libreswan-service.name";
  };

  meta = with lib; {
    description = "NetworkManager's libreswan plugin";
    inherit (networkmanager.meta) platforms;
  };
}
