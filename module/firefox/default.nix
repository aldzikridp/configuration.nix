{ pkgs, ...}:

let
myLibrewofl = pkgs.librewolf.override {
  nativeMessagingHosts = [ pkgs.ff2mpv ];

  extraPolicies =
    import ./policy.nix;

  extraPrefs =
    builtins.readFile ./config.js;

};
myFirefox = pkgs.firefox.override {
  nativeMessagingHosts = [ pkgs.ff2mpv ];

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
