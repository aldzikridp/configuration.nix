{ pkgs, ... }:
{
  programs.waybar = {
   enable = true;
   settings = {
    mainBar = {
    position = "bottom";
    height = 39;
    modules-left = ["tray" "sway/mode"];
    modules-center = ["sway/workspaces" "hyprland/workspaces"];
    modules-right = ["mpd" "idle_inhibitor" "pulseaudio" "network" "battery" "temperature" "clock"];
     "sway/window" = {
        max-length = 35;
     };
    "sway/mode" = {
        format = "Resize ";
    };
    mpd = {
        format = "{stateIcon}";
        server = "127.0.0.1";
        port = 6600;
        format-disconnected = "";
        format-stopped = " ";
        unknown-tag = "N/A";
        interval = 2;
        state-icons = {
            paused = "";
            playing = "";
        };
        tooltip-format = "MPD (connected)";
        tooltip-format-disconnected = "MPD (disconnected)";
        on-click = "${pkgs.mpc_cli}/bin/mpc --host localhost --port 6600 toggle";
    };
    idle_inhibitor = {
        format = "{icon}";
        format-icons = {
            activated = "";
            deactivated = "";
        };
    };
    tray = {
        spacing = 10;
    };
    clock = {
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format = " {:%H:%M}";
        format-alt = " {:%Y/%m/%d}";
    };
    cpu = {
        format = "{usage}% ";
        tooltip = false;
    };
    memory = {
        format = "{}% ";
    };
    temperature = {
        thermal-zone = 2;
        hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        interval = 5;
        format-icons = ["" "" "" "" ""];
    };
    backlight = {
        format = "{percent}% {icon}";
        format-icons = ["" ""];
    };
    battery = {
        states = {
            warning = 30;
            critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = ["" "" "" "" ""];
    };
    "battery#bat2" = {
        bat = "BAT2";
    };
    network = {
        format-wifi = "";
        format-ethernet = "󰈀";
        format-disconnected = "⚠";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        #on-click = "~/.config/waybar/nmtui";
    };
    #"network#openvpn" = {
    #    format = "VPN ";
    #    format-disconnected = "VPN ";
    #    on-click = "~/.config/waybar/vpn.sh";
    #};
    #"custom/vpn" = {
    #    interval = 5;
    #    tooltip-format = "{tooltip}";
    #    return-type = "json";
    #    format = "VPN {icon}";
    #    format-icons = [""""];
    #    exec = "$HOME/.config/waybar/vpn-status.sh";
    #    on-click = "~/.config/waybar/vpn.sh";
    #};
    pulseaudio = {
        format = "{volume}% {icon}";
        format-bluetooth = "{volume}% {icon}";
        format-bluetooth-muted = " {icon}";
        format-muted = "";
        format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            default = ["" "" ""];
        };
        on-click = "pavucontrol";
    };
    "custom/media" = {
        format = "{icon} {}";
        return-type = "json";
        max-length = 40;
        format-icons = {
            spotify = "";
            default = "🎜";
        };
        escape = true;
    };
    };
   };
   style =
   ''
   * {
    border: none;
    border-radius: 0;
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: RobotoMono Nerd Font;
    font-size: 15px;
    min-height: 0;
    }

    #waybar {
        background-color: transparent;
        color: rgba(228, 228, 228, 1);
        transition-property: background-color;
        transition-duration: .5s;
    }
    
    #workspaces button {
        color: #ffffff;
        background-color: rgba(0, 0, 0, 0.7);
        padding: 0 11px;
        border-radius: 50% 50% 50% 50%;
    }
    
    /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
    #workspaces button:hover {
        background: rgba(228, 228, 228, 0.4);
        color: rgba(0, 0, 0, 1);
        box-shadow: inherit;
        text-shadow: inherit;
        border-radius: 50% 50% 50% 50%;
    }
    
    #workspaces button.active {
        background-color: rgba(228, 228, 228, 1);
        color: rgba(0, 0, 0, 1);
        border-radius: 50% 50% 50% 50%;
    }

    #workspaces button.focused {
        background-color: rgba(228, 228, 228, 1);
        color: rgba(0, 0, 0, 1);
        border-radius: 50% 50% 50% 50%;
    }
    
    #workspaces button.urgent {
        background-color: rgba(255, 0, 0, 1);
    }
    
    #mode {
        background-color: rgba(228, 228, 228, 1);
        color: rgba(0, 0, 0, 1);
        border-radius: 20% 20% 20% 20% / 50% 50% 50% 50%;
        padding: 0 11px;
    }
    
    #clock,
    #battery,
    #cpu,
    #memory,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #custom-media,
    #tray,
    #mode,
    #idle_inhibitor,
    #custom-vpn,
    #mpd {
        padding: 0 10px;
        color: rgba(228, 228, 228, 1);
        background-color: rgba(0, 0, 0, 0.7);
    }
    
    #tray {
        padding: 0 11px;
        border-radius: 0px 25px 25px 0px;
    }
    
    #mpd {
        border-radius: 25px 0px 0px 25px;
    }
    
    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }
    
    
    label:focus {
        background-color: #000000;
    }
    
    
    #custom-media {
        background-color: #66cc99;
        color: #2a5c45;
        min-width: 100px;
    }
    
    #custom-media.custom-spotify {
        background-color: #66cc99;
    }
    
    #custom-media.custom-vlc {
        background-color: #ffa000;
    }

   '';
  };
}
