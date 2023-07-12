{

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

  #ManagedBookmarks = [ ];
  #NoDefaultBookmarks = true;

}
