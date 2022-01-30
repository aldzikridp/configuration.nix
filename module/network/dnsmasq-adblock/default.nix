{ pkgs, ... }:
let
  stevenblackhost = pkgs.stdenv.mkDerivation {
    name = "stevenblackhost";
    src = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
    });

   phases = [ "installPhase" ];
   
   # Minify host file
   installPhase = ''
     ${pkgs.gawk}/bin/awk '$1 == "0.0.0.0" {print "address=/"$2"/0.0.0.0/"}' $src > $out
   '';
  };

  notrackinghost = pkgs.stdenv.mkDerivation {
    name = "notrackinghost";
    src = (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt";
    });

   phases = [ "installPhase" ];
   
   # Minify host file
   installPhase = ''
     ${pkgs.gawk}/bin/awk '$1 == "0.0.0.0" {print "address=/"$2"/0.0.0.0/"}' $src > $out
   '';
  };
in {
  services.dnsmasq = {
    enable = true;
    servers = ["127.0.0.1#5300"];
    resolveLocalQueries = false;
    extraConfig = ''
      conf-file="${stevenblackhost}"
      conf-file="${notrackinghost}"
      cache-size=1000
      domain-needed
      bogus-priv
    '';
  };
}
