{ pkgs, ...}:

let
myLibrewofl = pkgs.librewolf.override {
  extraNativeMessagingHosts = [ pkgs.ff2mpv ];

  extraPolicies =
    import ./policy.nix;

  extraPrefs =
    builtins.readFile ./config.js;

};
myFirefox = pkgs.firefox.override {
  extraNativeMessagingHosts = [ pkgs.ff2mpv ];

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
