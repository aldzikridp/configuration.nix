{ config, pkgs, lib, ... }:
let
  MYTERM = "exec ${pkgs.foot}/bin/footclient";
  EXEC_TERM = "exec ${MYTERM} --single-instance";
  FZF_LAUNCHER = ''
    ${MYTERM} \
    -o close_on_child_death=yes \
    -o font_size=15 \
    -o enable_audio_bell=no \
    -o remember_window_size=no \
    -o initial_window_width=50c \
    -o initial_window_height 10c \
    --class fzf-launcher --detach
  '';
  RUN_MENU = ''
    exec ${FZF_LAUNCHER} sh -c "compgen -c | fzf | xargs -r swaymsg exec"
  '';
  LAUNCH_MUSIC = ''
    exec ${MYTERM} \
    -o allow_remote_control=yes \
    -o enabled_layouts=horizontal \
    -o window_border_width=0 \
    -o window_padding_width=3 \
    on_song_change_ncmpcpp
  '';
  LOCK_SCREEN = ''exec "${pkgs.swaylock-fancy}/bin/swaylock-fancy --daemonize; ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null"'';
  SUSPEND = ''exec "${pkgs.swaylock-fancy}/bin/swaylock-fancy --daemonize && systemctl suspend"'';

in
{
  imports = [
    ./waybar.nix
    ./mako.nix
    ./wofi.nix
  ];
  home.packages = with pkgs;[
    wl-clipboard
    wf-recorder
    wdisplays
    adwaita-icon-theme
    slurp
    imv
  ];
  services.swayidle = {
    enable = true;
    timeouts = [
          { timeout = 600; command = "${pkgs.swaylock-fancy}/bin/swaylock-fancy --daemonize";}
          {
            timeout = 900;
            command = ''${pkgs.sway}/bin/swaymsg "output * dpms off"'';
            resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * dpms on"'';
          }
    ];
  };
  programs.swaylock = {
    enable = true;
  };
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; #Check fail when setting wallpaper
    wrapperFeatures.gtk = true;
    config = {
      defaultWorkspace = "workspace number 1";
      bars = [ {
        command = "${pkgs.waybar}/bin/waybar";
      } ];
      focus.followMouse = false;
      fonts = {
        names = ["RobotoMono Nerd Font"];
        style = "Medium";
        size = 10.0;
      };
      gaps = {
        inner = 10;
        outer = 0;
        smartBorders = "on";
      };
      window = {
        border = 3;
      };
      floating = {
        border = 3;
      };
      modifier = "Mod4";
      keybindings =
        let modifier = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          "${modifier}+Return"="${MYTERM}";
          "${modifier}+d"="exec wofi";
          #"${modifier}+p"="exec ${FZF_LAUNCHER} _fzf_pass";
          #"${modifier}+Shift+m"="${LAUNCH_MUSIC}";
          "${modifier}+Ctrl+l"="${LOCK_SCREEN}";
          "${modifier}+Ctrl+s"="${SUSPEND}";
          "XF86AudioRaiseVolume"="exec pamixer -i 1";
          "XF86AudioLowerVolume"="exec pamixer -d 1";
          "XF86AudioMute"="exec pamixer -t";
          "XF86AudioMicMute"="exec pamixer --source 46 -t";
          "XF86MonBrightnessUp"="exec brightnessctl set +5%";
          "XF86MonBrightnessDown"="exec brightnessctl set 5%-";

        };
      input = {
        "type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          natural_scroll = "disabled";
          middle_emulation = "enabled";
        };
      };
      output = {
        "*" = {
          bg = "${config.xdg.userDirs.pictures}/.wallpaper fill";
        };
      };
    };
    extraConfig = ''
      for_window [app_id="fzf-launcher"] focus, floating enabled, border pixel 0
      for_window [app_id="pavucontrol"] floating enable
      for_window [app_id="keepassxc"] floating enable
      for_window [app_id="mpv"] floating enable
      for_window [app_id="termfloat"] floating enable
      for_window [app_id="xdg-desktop-portal-gtk"] floating enable
      for_window [app_id="nm-connection-editor"] floating enable
      client.focused #FFFFFFFF #FFFFFFFF #000000FF #FFFFFFFF
      client.focused_inactive #000000B3 #000000B3 #FFFFFFFF #000000B3
      client.unfocused #000000B3 #000000B3 #FFFFFF66 #000000B3

      bindsym Print exec grim -g "$(slurp)" ~/Pictures/$(date +'%Y-%m-%d-%H%M%S_Screenshot.png')

      bindsym Ctrl+Print exec wf-recorder --audio -f ~/Videos/$(date +"%Y-%m-%d_%H:%M:%S_Screenrecord.mp4")
      bindsym Ctrl+Shift+Print exec wf-recorder --audio -g "$$(slurp)" -f ~/Videos/$(date +"%Y-%m-%d_%H:%M:%S_Screenrecord.mp4")
      bindsym Ctrl+Shift+BackSpace exec killall -s SIGINT wf-recorder

      output * bg ~/.config/sway/wallpaper.jpg fill
    '';
  };
}
