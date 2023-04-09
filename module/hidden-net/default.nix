{ config, ... }:
{
  services.i2pd = {
    enable = true;
    bandwidth = 500;
    upnp.enable = true;
    proto.httpProxy.enable = true;
    enableIPv6 = true;
  };
}
