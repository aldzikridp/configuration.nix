{ pkgs, lib, ... }:
let
  
  #gopassff-host = pkgs.passff-host.overrideAttrs (oldAttrs: {
  #  patchPhase = ''
  #    sed -i 's#COMMAND = "pass"#COMMAND = "${pkgs.gopass}/bin/gopass"#' src/passff.py
  #  '';
  #});
extensions = {
  # Can use extension https://github.com/mkaply/queryamoid to query amo
  "Tab-Session-Manager@sienori" = "tab-session-manager";
  "uBlock0@raymondhill.net" = "ublock-origin";
    #"passff@invicem.pro" = "passff";
  "@testpilot-containers" = "multi-account-containers";
  "@contain-facebook" = "facebook-container";
  "cliget@zaidabdulla.com" = "cliget";
  "ff2mpv@yossarian.net" = "ff2mpv";
  #"7esoorv3@alefvanoon.anonaddy.me" = "libredirect";
  "jid1-BoFifL9Vbdl2zQ@jetpack" = "decentraleyes";
    #"bukubrow@samhh.com" = "bukubrow";
  "addon@fastforward.team" = "fastforwardteam";
  "{0da2e603-21ba-4422-8049-b6d9e013ed84}" = "image-reverse-search";
  "{4c421bb7-c1de-4dc6-80c7-ce8625e34d24}" = "load-reddit-images-directly";
  "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}" = "gopass-bridge";
};

in
{
  programs.firefox = {
    enable = true;
    #package = pkgs.firefox.override {
    #  # Passff doesn't work when inserted in programs.firefox.nativeMessagingHosts
    #      nativeMessagingHosts = [ gopassff-host ];
    #};
    nativeMessagingHosts = [
      pkgs.ff2mpv
      #pkgs.bukubrow
      pkgs.gopass-jsonapi
    ];
    policies = {
      ExtensionSettings =
        lib.mapAttrs
          (_: name: {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
            default_area = "navbar";
          })
          extensions;
      DisableFirefoxStudies = true;
      DisablePocket    = true;
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;
      PasswordManagerEnabled = false;


      HardwareAcceleration    = true;
      DontCheckDefaultBrowser = true;
      RequestedLocales        = [ "en-US" ];


      FirefoxHome =
      { Locked = true;

        TopSites          = false;
        SponsoredTopSites = false;
        Highlights        = false;
        Pocket            = false;
        SponsoredPocket   = false;
        Snippets          = false;
      };


      SearchBar               = "unified";
      ShowHomeButton          = false;
      DisplayBookmarksToolbar = false;

      UserMessaging =
      { WhatsNew                 = false;
        FeatureRecommendations   = false;
        ExtensionRecommendations = false;
        UrlbarInterventions      = false;
        MoreFromMozilla          = false;
        SkipOnboarding           = true;
      };


      EnableTrackingProtection =
      { Value          = true;
        Cryptomining   = true;
        Fingerprinting = true;
      };

      Permissions =
      {
        Autoplay = {
          Default = "block-audio-video";
        };
      };
    };
  };
}
