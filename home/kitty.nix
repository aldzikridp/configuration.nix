{
  programs.kitty = {
    enable = true; # required for the default Hyprland config
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    shellIntegration = {
      enableBashIntegration = true;
    };
    settings = {
      "background_opacity" = "0.7";
      "adjust_column_width" = "1";
      "linux_display_server" = "wayland";
      "enable_audio_bell" = "no";
      "share_connections" = "yes";
    };
    keybindings = {
      "ctrl+shift+n" = "new_os_window_with_cwd";
    };
  };
}
