{ config, ... }:
{
  services.i2pd = {
    enable = true;
    bandwidth = 1000;
    upnp.enable = true;
    proto = {
      httpProxy.enable = true;
      http.enable = true;
    };
    enableIPv6 = true;
    port = 17341;
  };
}
