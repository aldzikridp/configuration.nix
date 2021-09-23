{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
      (pass.withExtensions (ext: with ext; [ pass-import ]))
    ];
}
