{ pkgs, ... }:
{
  home.packages = with pkgs; [
    poppler-utils
    chafa
    dragon-drop
  ];
  programs = {
    lf = {
      enable = true;
      previewer = {
        keybinding = "i";
        source = "${./lf-previewer.sh}";
      };
      commands = {
        open = ''
          ''\&{{
            for file in $fx; do
               mime=$(file --mime-type -Lb "$file")
               ext="''${file##*.}"

               if [[ "$mime" == "text/html" ]]; then
                firefox "$file" &
              elif [[ "$ext" == "pdf" || "$ext" == "epub" || "$ext" == "cbz" || "$ext" == "cbr" ]]; then
                zathura "$file" &
              elif [[ "$ext" == "docx" || "$ext" == "pptx" || "$ext" == "xlsx" || "$ext" == "odt" || "$ext" == "odp" || "$ext" == "ods" ]]; then
                libreoffice "$file" &
              elif [[ "$mime" == "image/"* ]]; then
                imv "$file" &
              elif [[ "$mime" == "video/"* || "$mime" == "audio/"* ]]; then
                if [[ "$mime" == "audio/ogg" ]]; then
                  mpv --no-terminal --force-window=yes "$file" &
                else
                  mpv --no-terminal --force-window=yes --fs "$file" &
                fi
              elif [[ "$mime" == "text/"* || "$ext" =~ ^(xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart)$ ]]; then
                ''${VISUAL:-$EDITOR} "$file"
              elif [[ "$ext" =~ ^(7z|ace|ar|arc|bz2|cab|cpio|cpt|deb|dgc|dmg|gz|iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip)$ ]]; then
                ${pkgs.atool}/bin/atool --list --each -- "$file" | $PAGER
              elif [[ "$mime" == *"font"* ]]; then
                fontforge "$file" &
              else
                ${pkgs.xdg-utils}/bin/xdg-open "$file" &
              fi
            done
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

        copypath = ''
          &{{
            if [ -n "$fx" ]; then
              printf "%s\n" $fx | wl-copy
            else
              wl-copy "$f"
            fi
          }}
        '';
      };
      keybindings = {
        o = "open";
        ad = ":push %mkdir<space>";
        af = ":push %touch<space>";
        D = "dragon";
        Y = "copypath";
      };
       settings = {
         shell = "sh";
         drawbox = true;
         relativenumber = true;
         icons = true;
         shellopts = "-eu";
         ifs = "\n";
         scrolloff = 10;
       };
       extraConfig = ''
         set previewer ${./lf-previewer.sh}
       '';


    };
  };
}
