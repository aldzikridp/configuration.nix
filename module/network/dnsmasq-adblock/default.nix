{ pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);
    host1 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/e3c782a94dd950e92cb28d1967b7c67ce180a09c/hostnames.txt";
      #sha256 = lib.fakeSha256;
      sha256 = "0s4h87ni8n8hyyd02h9pnbpcdbkkiw7drb8flbpyx8xb9gm3gpxg";
    });
    host2 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/7b45134c8d9e7104a200739e030aa5d8a467c6cb/hosts";
      #sha256 = lib.fakeSha256;
      sha256 = "06gf3crslifnxhxz5a9d2d1d29xjp18f19k36d35xcp0syd76pwa";
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
    resolveLocalQueries = false;
    settings = {
      server = ["127.0.0.1#5300"]; #dnscrypt-proxy2 port
      conf-file = [
        "${adblockhost}" 
        "${pkgs.dnsmasq}/share/dnsmasq/trust-anchors.conf"
      ];
      cache-size = 1000;
      domain-needed = true;
      bogus-priv = true;
    };
  };
}
