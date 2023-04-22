{ lib, pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);
    host1 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/c1ac9910387e7871e225bc35ccccbe200d8a1bde/hostnames.txt";
      #sha256 = lib.fakeSha256;
      sha256 = "1qnkq3n1w2h9fskb6dhqa54iv4zdv88nlx4vwpfk2p5zrdxwqsvh";
    });
    host2 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/ee692bbaa3097bd847f11e5230a6999a3bc01e97/hosts";
      #sha256 = lib.fakeSha256;
      sha256 = "1qw053pv7h7a07vyyjb7aw3s8jhckiy3laxyf6hcfsx52x8gwf9l";
    });
    #host3 = (builtins.fetchurl { url = "https://block.energized.pro/assets/sources/filter/abpindo.txt"; });
    #host4 = (builtins.fetchurl { url = "https://block.energized.pro/ultimate/formats/hosts.txt"; });

   phases = [ "installPhase" ];
   
   # Minify host file
   installPhase = ''
     ${pkgs.gawk}/bin/awk '$1 == "0.0.0.0" { if (!a[$2]++) { print "address=/"$2"/#"}}' $custom $host1 $host2 > $out
   '';
  };

in {
  services.dnsmasq = {
    enable = true;
    servers = ["127.0.0.1#5300"]; #dnscrypt-proxy2 port
    resolveLocalQueries = false;
    extraConfig = ''
      conf-file="${adblockhost}"
      conf-file="${pkgs.dnsmasq}/share/dnsmasq/trust-anchors.conf"
      cache-size=1000
      domain-needed
      bogus-priv
    '';
  };
}
