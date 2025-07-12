{
  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    shellAliases = {
      #ssh = "kitty +kitten ssh";
      #icat = "kitty +kitten icat";
      scan_qr = ''grim -g "$(slurp)" - | zbarimg PNG:-'';
    };
    #sessionVariables = {
    #  VISUAL = "nvim";
    #  EDITOR = "nvim";
    #};
    historyControl = [ "ignoreboth" ];
    historyIgnore = [
      "sway"
      "ls"
    ];
    initExtra = ''
      set -o vi
      
      if command -v fzf-tab-bash >/dev/null; then
        source "$(fzf-tab-bash)"
        bind -x '"\t": fzf_bash_completion'
      fi
      
    '';
    bashrcExtra = ''
      osc7_cwd() {
          local strlen=''${#PWD}
          local encoded=""
          local pos c o
          for (( pos=0; pos<strlen; pos++ )); do
              c=''${PWD:''$pos:1}
              case "''$c" in
                  [-/:_.!\'\(\)~[:alnum:]] ) o="''${c}" ;;
                  * ) printf -v o '%%%02X' "''\'''${c}" ;;
              esac
              encoded+="''${o}"
          done
          printf '\e]7;file://%s%s\e\\' "''${HOSTNAME}" "''${encoded}"
      }
      #PROMPT_COMMAND=''${PROMPT_COMMAND:+''${PROMPT_COMMAND%;}; }osc7_cwd
      starship_precmd_user_func="osc7_cwd"
    '';
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.oh-my-posh = {
    enable = false;
    enableBashIntegration = true;
    useTheme = "multiverse-neon";
  };
}
