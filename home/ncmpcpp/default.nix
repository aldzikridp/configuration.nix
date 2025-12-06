{ pkgs, config, ... }:
{
  home.packages = with pkgs;[
    (writeShellScriptBin "on_song_change_ncmpcpp" (builtins.readFile ./on_song_change_ncmpcpp.sh))
    mpc
  ];
  programs.ncmpcpp = {
    enable = true;
    package = (pkgs.ncmpcpp.override { visualizerSupport = true; });
    mpdMusicDir = "${config.home.homeDirectory}/Music";
    settings = {
      #mpd_host = "/tmp/mpd_socket";
      mpd_host = "localhost";
      mpd_port = 6600;
      mpd_crossfade_time = "2";
      
      visualizer_data_source = "/tmp/mpd.fifo";
      visualizer_in_stereo = "no";
      visualizer_type = "wave";
      visualizer_output_name = "my_fifo";
      visualizer_look = "│┃";
      visualizer_color = "default";
      
      header_visibility = "no";
      header_window_color = "default";
      volume_color = "default";
      state_line_color = "black";
      
      playlist_display_mode = "classic";
      song_list_format = "{{%t}|{%f}}{$R%a}";
      now_playing_prefix = "$b$2";
      now_playing_suffix = "$/b$9";
      
      progressbar_look = "▃▃ ";
      progressbar_elapsed_color = "white";
      statusbar_visibility = "no";
      statusbar_color = "default";
      song_status_format = "{{%a{ - %t}}|{ - %f}{ - %b{ (%y)}}}";
      
      song_library_format = "{{%a - %t}|{%f}}{$R%l}";
      empty_tag_color = "black";
      
      colors_enabled = "yes";
      main_window_color = "default";
      centered_cursor = "yes";
      enable_window_title = "yes";
      external_editor = "nvim";
      
      execute_on_song_change = "on_song_change_ncmpcpp get";

    };
  };
}
