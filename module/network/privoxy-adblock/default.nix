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
in
{
  services.privoxy = {
    enable = true;
    inspectHttps = true;
    userFilters = (builtins.readFile ./custom.filter);
    userActions = (builtins.readFile ./custom.action);
    settings = {
      receive-buffer-size = 104857600;
      logfile = "/tmp/privoxy.log";
      ca-cert-file = "${certs}/cacert.crt";
      ca-key-file  = "${certs}/cakey.pem";
    };
  };
  security.pki.certificateFiles = [ "${certs}/cacert.crt" ];
}
