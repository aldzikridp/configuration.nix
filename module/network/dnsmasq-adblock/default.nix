{ pkgs, ... }:
let
  adblockhost = pkgs.stdenv.mkDerivation {
    name = "adblockhost";
    custom = builtins.toFile"customhost"(builtins.readFile ./customblock);

    phases = [ "installPhase" ];
   
    # Minify host file and convert to dnsmasq format
    installPhase = ''
      ${pkgs.gawk}/bin/awk '$1 == "0.0.0.0" { if (!a[$2]++) { print "address=/"$2"/#"}}' $custom ${pkgs.unstable.pkgs.stevenblack-blocklist}/hosts > $out
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
