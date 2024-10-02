{ pkgs, lib, ... }:
{
  imports = [
    ./waybar.nix
    ./wofi.nix
    ./mako.nix
  ];
  wayland.windowManager.hyprland.enable = true; # enable Hyprland
  wayland.windowManager.hyprland.extraConfig = ''
  exec-once=${pkgs.waybar}/bin/waybar
  exec-once=${pkgs.mako}/bin/mako
  exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
  '';
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    bind =
      [
        "$mod, F, exec, firefox"
        "$mod, D, exec, wofi"
        "$mod, Return, exec, kitty"
        ''
        ,Print,exec, grim -g "$(slurp)" ~/Pictures/$(date +'%Y-%m-%d-%H%M%S_Screenshot.png')
        ''
        "$mod, C, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo" # dwindle
        "$mod, S, togglesplit" # dwindle

# Move focus with mod + arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

# Switch workspaces with mod + [0-9]
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

# Move active window to a workspace with mod + SHIFT + [0-9]
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

# Example special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

# Scroll through existing workspaces with mod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (builtins.genList (i:
            let ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          )
          9)
      );
      bindel = [
        ",XF86AudioRaiseVolume,exec,pamixer -i 1"
        ",XF86AudioLowerVolume,exec,pamixer -d 1"
        ",XF86AudioMute,exec,pamixer -t"
        ",XF86AudioMicMute,exec,pamixer --source 46 -t"
        ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
        ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
      ];
  };
}
