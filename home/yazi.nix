{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      opener = {
        "video" = [{
          run = ''mpv --no-terminal "$@" 2&>/dev/null'';
          orphan = true;
        }];
        "image" = [{
          run   = ''imv "$@"'';
          orphan = true;
        }];
        "pdf" = [{
          run   = ''zathura "$@"'';
          orphan = true;
        }];
      };
      open.prepend_rules = [
        {
          mime = "image/*";
          use  = "image";
        }
        {
          mime = "video/*";
          use  = "video";
        }
        {
          mime = "application/pdf";
          use = ["zathura"];
        }
      ];
    };
  };
}
