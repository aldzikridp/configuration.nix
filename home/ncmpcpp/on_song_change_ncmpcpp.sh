#!/usr/bin/env bash

function launch() {
    kitty @ set-tab-title music
    kitty @ set-window-title cover
    kitty @ new-window --title ncmpcpp ncmpcpp
    kitty @ resize-window --increment 23
    set_cover
    export PS1=""
    exec sh
}

function set_cover() {
kitty @ send-text \
    --match title:cover \
    "clear && kitty icat --align=center --transfer-mode=stream '$COVER' \r"
}

function get_cover() {
    music_dir="$HOME/Music/"
    mpd_host="localhost"
    mpd_port=6600
    current_music="$(mpc --host="$mpd_host" --format %file% current)"
    current_music_dir="$music_dir$(dirname "$current_music")"

    COVER="$(fd -e png -e jpg cover -1 "$current_music_dir")"
    if [[ -n $COVER ]]
    then
        return 0
    fi

    ffmpeg -i "$music_dir$current_music" "/tmp/cover" -y &> /dev/null
    STATUS=$?

    if [[ $STATUS -eq 0 ]]
    then
        COVER="/tmp/cover"
        return 0
    fi

    COVER="$HOME/.config/ncmpcpp/art.png"
}


if [[ $1 == "get" ]]
then
    get_cover
    set_cover
else
    get_cover
    launch
fi

