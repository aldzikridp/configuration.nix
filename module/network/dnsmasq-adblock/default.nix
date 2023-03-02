{ pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);
    host1 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/1ae68b1ed4d32f6e875171af5395a1e411e55551/hostnames.txt";
      sha256 = "0hdrd2dfskrip8drfxr9nlkpx48c4pm7q3sb61shsnjy0k9lgq5a";
    });
    host2 = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/b6d5cce60ac99ae572c56ef8d2b2dc01530707e1/hosts";
      sha256 = "0j7mdiajbwjapgj4sabmhri65lwiryqbadpkb7k8ah56lx4nbn97";
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
