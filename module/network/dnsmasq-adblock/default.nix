{ pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);
    host1 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"; });
    host2 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; });
    host3 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"; });
    host4 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt"; });
    host5 = (builtins.fetchurl { url = "https://block.energized.pro/ultimate/formats/hosts.txt"; });
    host6 = (builtins.fetchurl { url = "https://block.energized.pro/assets/sources/filter/abpindo.txt"; });

   phases = [ "installPhase" ];
   
   # Minify host file
   installPhase = ''
     ${pkgs.gawk}/bin/awk '$1 == "0.0.0.0" { if (!a[$2]++) { print "address=/"$2"/0.0.0.0"}}' $custom $host1 $host2 $host3 $host4 $host5 $host6 > $out
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
