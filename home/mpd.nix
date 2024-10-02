{ config, ... }:
{
  services.mpd = {
    enable = true;
    dataDir = "${config.home.homeDirectory}/.mpd";
    musicDirectory = "${config.xdg.userDirs.music}";
    #playlistDirectory = "~/Music/mpd_playlist";
    #dbFile = "~/.mpd/mpd.db";
    extraConfig = ''
    audio_output {
      type "pipewire"
      name "pipewire audio"
    }

    audio_output {
    	type                    "fifo"
    	name                    "my_fifo"
    	path                    "/tmp/mpd.fifo"
    	format                  "44100:16:2"
    }

    '';
  };
}
