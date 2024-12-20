{
  programs.bash = {
    enable = true;
    shellAliases = {
      ssh = "kitty +kitten ssh";
      icat = "kitty +kitten icat";
      scan_qr = ''grim -g "$(slurp)" - | zbarimg PNG:-'';
    };
    sessionVariables = {
      VISUAL = "nvim";
      EDITOR = "nvim";
    };
    initExtra = ''
      set -o vi
      
      if command -v fzf-tab-bash >/dev/null; then
        source "$(fzf-tab-bash)"
        bind -x '"\t": fzf_bash_completion'
      fi
      shopt -s histappend
      # Store bash history immediatly (history -a)
      # Up key show local terminal history rather than globally (history -n)
      #export PROMPT_COMMAND='$PROMPT_COMMAND;history -a;history -n'
      PROMPT_COMMAND='history -a; history -n'
      
      # CONTROL BASH HISTORY
      # ignorespace = don’t save lines which begin with a <space> character
      # ignoredups = don’t save lines matching the previous history entry
      # ignoreboth = use both ‘ignorespace’ and ‘ignoredups’
      # erasedups = eliminate duplicates across the whole history
      HISTCONTROL=ignorespace:erasedups
      
      # Ignore specific commands
      #HISTIGNORE='ls *:ls:cd *:cd:ranger *:ranger:rm *:sway *:clear *'
      HISTIGNORE='sway *:clear *'

      # eval "$(starship init bash)"
    '';
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
}
