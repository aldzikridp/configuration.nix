{ pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);
    host1 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/6e325878f1f64903cd8029dd2b1cf46f02e6d054/hostnames.txt";
      sha256 = "0lhdaihxs1g6kkg6vs4psp1bfxdcclrxdqv06bjjaz06ps8zdqan";
    });
    host2 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/bc271a3f6a55c8da8a0b6fd46ad34647861019c0/hosts";
      sha256 = "0qnarrf0xihnwgnaznxjix954nd1a16lzccj3a1h7bwsqszfirma";
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
