{ pkgs, ...}:

let
myFirefox = pkgs.firefox.override {

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
