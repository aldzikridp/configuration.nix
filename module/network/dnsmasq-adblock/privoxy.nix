#########################################
#              WARNING                  #
#########################################
# Privoxy is less efficient than uBlock
# and reauire much more cpu than
# browser + ublock itself
# consider just using ublock

{ pkgs, ... }:
let
  certs = pkgs.runCommand "generate-certs"
    { buildInputs = [ pkgs.openssl ]; }
    ''
      mkdir $out

      openssl ecparam -out $out/cakey.pem -name secp384r1 -genkey
      openssl req -new -x509 -key $out/cakey.pem -sha384 -days 3650 -out $out/cacert.crt -extensions v3_ca -subj "/O=Privoxy CA/CN=Privoxy CA"
    '';

  adblockList = pkgs.stdenv.mkDerivation {
    name = "adblockList";
    list1 = (builtins.fetchurl { url = "https://easylist.to/easylist/easylist.txt"; });
    list2 = (builtins.fetchurl { url = "https://easylist.to/easylist/easyprivacy.txt"; });
    list3 = (builtins.fetchurl { url = "https://easylist.to/easylist/fanboy-annoyance.txt"; });
    list4 = (builtins.fetchurl { url = "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt"; });
    list5 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt"; });
    list6 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt"; });
    list7 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"; });
    list8 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"; });
    list9 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt"; });
    list10 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt"; });
    list11 = (builtins.fetchurl { url = "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt"; });

    phases = [ "installPhase" ];

    installPhase = ''
      ${pkgs.haskellPackages.adblock2privoxy}/bin/adblock2privoxy -p $out/ $list1 $list2 $list3 $list4 $list5 $list6 $list7 $list8 $list9 $list10 $list11
    '';
  };
in
{
  services.privoxy = {
    enable = true;
    inspectHttps = true;
    settings = {
      receive-buffer-size = 104857600;
      logfile = "/tmp/privoxy.log";
      ca-cert-file = "${certs}/cacert.crt";
      ca-key-file  = "${certs}/cakey.pem";
      filterfile = [
       "${adblockList}/ab2p.filter"
       "${adblockList}/ab2p.system.filter"
      ];
      actionsfile = [
        "${adblockList}/ab2p.action"
        "${adblockList}/ab2p.system.action"
      ];
    };
  };
  security.pki.certificateFiles = [ "${certs}/cacert.crt" ];
}
