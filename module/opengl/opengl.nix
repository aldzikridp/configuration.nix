{ config, pkgs, lib, ... }:

let
   mesa_version = "20.3.5";
   mesa_src = pkgs.fetchurl {
     url = "https://mesa.freedesktop.org/archive/mesa-${mesa_version}.tar.xz";
     sha256 = "1klifqyr54q8ar8sncykgqllil98q1ma4i6g9j2c18yzcggp56lh";
   };
   mesa_20_3 = pkgs.mesa.overrideAttrs (a: { src = mesa_src; version = mesa_version; patches = lib.sublist 1 2 a.patches; });
   mesa_20_3_5 = pkgs.pkgsi686Linux.mesa.overrideAttrs (a: { src = mesa_src; version = mesa_version; patches = lib.sublist 1 2 a.patches; });
 in
{
    hardware = {
        opengl = {
           driSupport32Bit = true;
           package = lib.mkForce mesa_20_3.drivers;
           package32 = lib.mkForce mesa_20_3_5.drivers;
        };
   };
}
