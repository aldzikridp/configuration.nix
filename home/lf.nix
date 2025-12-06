{ pkgs, ... }:
{
  programs = {
    lf = {
      enable = true;
      previewer = {
        keybinding = "i";
        source = "${pkgs.ctpv}/bin/ctpv";
      };
      commands = {
        open = "$set -f; rifle -p 0 $fx";

        open-with = ''
          ''${{
            set -f
            rifle -l $fx
            read -p "Open with: " method
            rifle -p $method $fx
          }}
        '';

        delete = ''
          %{{
            set -f
            count=$(printf "$fx\n" | wc -l)
            printf "delete $count selected?[y/n]"
            read ans
            [ "$ans" = "y" ] && rm -rf $fx
          }}
        '';

        dragon = ''
          &{{
            ${pkgs.dragon-drop}/bin/dragon --and-exit -A $fx
          }}
        '';

        extract = ''
          ''${{
              set -f
              case $f in
                  *.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar xjvf $f;;
                  *.tar.gz|*.tgz) tar xzvf $f;;
                  *.tar.xz|*.txz) tar xJvf $f;;
                  *.zip) 7z x $f;;
                  *.rar) unrar x $f;;
                  *.7z) 7z x $f;;
              esac
          }}
        '';
      };
      keybindings = {
        o = "open";
        O = "open-with";
        ad = ":push %mkdir<space>";
        af = ":push %touch<space>";
        D = "dragon";
      };
      settings = {
       shell = "sh";
       drawbox = true;
       relativenumber = true;
       icons = true;
       shellopts = "-eu";
       ifs = "\n";
       scrolloff = 10;
       cleaner = "${pkgs.ctpv}/bin/ctpv";
      };
      extraConfig = ''
        &${pkgs.ctpv}/bin/ctpv -s $id
        cmd on-quit %${pkgs.ctpv}/bin/ctpv -e $id
        set cleaner ${pkgs.ctpv}/bin/ctpvclear
      '';
    };
    ranger.enable = true;
    ranger.rifle = [
    {
      condition = "ext x?html?, has firefox,env WAYLAND_DISPLAY, flag f";
      command = ''firefox -- "$@"'';
    }
    
      # misc
      {
        condition = "mime ^text, label editor";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition = "mime ^text, label pager";
        command = ''$PAGER -- "$@"'';
      }
      {
        condition =
          "!mime ^text, label editor, ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition =
          "!mime ^text, label pager, ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''$PAGER -- "$@"'';
      }
      {
        condition = "ext 1";
        command = ''man "$1"'';
      }
      # audio/video
      {
        # with gui
        condition = "mime ^video|^audio, has mpv, env WAYLAND_DISPLAY, flag f";
        command = ''mpv --force-window=yes --fs -- "$@"'';
      }
      {
        # no gui
        condition = "mime ^audio/ogg$, has mpv, terminal";
        command = ''mpv --force-window=yes -- "$@"'';
      }
      # images
      {
        condition = "mime ^image, has imv, env WAYLAND_DISPLAY, flag f";
        command = ''${pkgs.imv}/bin/imv -- "$@"'';
      }
      # documents
      {
        condition = "ext pdf|docx|epub|cb[rz], has zathura, env WAYLAND_DISPLAY, flag f";
        command = ''${pkgs.zathura}/bin/zathura -- "$@"'';
      }
      {
        condition = "ext docx?, has catdoc, terminal";
        command = ''${pkgs.catdoc}/bin/catdoc -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext pptx?|od[dfgpst]|docx?|sxc|xlsx?|xlt|xlw|gnm|gnumeric, has libreoffice, env WAYLAND_DISPLAY, flag f";
        command = ''${pkgs.libreoffice}/bin/libreoffice -- "$@"'';
      }

      # archives
      {
        condition = "ext 7z, has 7z";
        command = ''${pkgs.p7zip}/bin/7z -p l "$@" | $PAGER'';
      }
      # ext ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz,     has atool = atool --list --each -- "$@" | $PAGER
      # ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool = atool --list --each -- "$@" | $PAGER
      # ext 7z|ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz,  has atool = atool --extract --each -- "$@"
      # ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool = atool --extract --each -- "$@"
      {
        condition =
          "ext ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz, has atool";
        command = ''${pkgs.atool}/bin/atool --list --each -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool";
        command = ''${pkgs.atool}/bin/atool --list --each -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext 7z|ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz, has atool";
        command = ''${pkgs.atool}/bin/atool --extract --each -- "$@"'';
      }
      {
        condition =
          "ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool";
        command = ''${pkgs.atool}/bin/atool --extract --each -- "$@"'';
      }

      # fonts
      {
        condition = "mine ^font, has fontforge, env WAYLAND_DISPLAY, flag f";
        command = ''${pkgs.fontforge}/bin/fontforge "$@"'';
      }

      # generic
      {
        condition = "label open, has xdg-open";
        command = ''${pkgs.xdg-utils}/bin/xdg-open "$@"'';
      }
      {
        condition =
          "label editor, !mime ^text, !ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition =
          "label pager, !mime ^text, !ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''$PAGER -- "$@"'';
      }
    ];
  };
}
