{ pkgs, ...}:

let
myLibrewofl = pkgs.librewolf.override {
  nativeMessagingHosts = [ pkgs.ff2mpv ];

#  extraPolicies =
#    import ./policy.nix;

  extraPrefs =
    builtins.readFile ./config-librewolf.js;

};
myFirefox = pkgs.firefox.override {
  nativeMessagingHosts = [ pkgs.ff2mpv ];

  extraPolicies =
    import ./policy-firefox.nix;

  extraPrefs =
    builtins.readFile ./config-firefox.js;
};

in {
  environment.systemPackages = with pkgs; [
    myFirefox
    myLibrewofl
  ];
}
