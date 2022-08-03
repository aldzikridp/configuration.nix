{ pkgs, ...}:

let
myFirefox = pkgs.librewolf.override {

  extraPolicies =
    import ./policy.nix;

  extraPrefs =
    builtins.readFile ./config.js;

};
in {
  environment.systemPackages = with pkgs; [
    myFirefox
  ];
}
