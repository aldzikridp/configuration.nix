let
    vpn = import ../../secrets/wg-id.nix;
in

{
  networking.wg-quick.interfaces = {
    wg0 = {
      address = vpn.clientip;
      privateKey = vpn.privateKey;
      dns = [ "1.1.1.1" ];
      
      peers = [
        {
          publicKey = vpn.publicKey;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = vpn.endpoint;
          persistentKeepalive = 25;
        }
      ];
    };
  };
}

