{ config, ... }:
{
  # Enable dnscrypt client
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = ["127.0.0.1:5300"];
      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
      server_names = [
        "moulticast-sg-ipv6"
        "dnswarden-asia-uncensor-dcv6"
        "sgp-dn53-ipv6"
        "dnscrypt-sg-blahdns-ipv6"
        "id-gmail-ipv6"
        "wevpn-singapore"
        "moulticast-sg-ipv4"
        "dnscrypt-sg-blahdns-ipv4"
        "dnswarden-asia-uncensor-dcv4"
        "id-gmail"
        "saldnssg01-conoha-ipv4"
        "sgp-dn53"
      ];
    };
  };
}
