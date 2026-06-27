#!/bin/sh
# lf previewer script

FILE_PATH="$1"
PV_WIDTH="$2"
PV_HEIGHT="$3"

MIME=$(file --mime-type -Lb "$FILE_PATH")

case "$MIME" in
    image/*)
        # Use chafa for Sixel image previews
        chafa -f sixel -s "${PV_WIDTH}x${PV_HEIGHT}" --animate off --polite on "$FILE_PATH"
        ;;
    video/*)
        # Extract frame at 1s and pipe to chafa for Sixel thumbnail
        #ffmpeg -i "$FILE_PATH" -ss 00:00:01 -vframes 1 -f image2pipe -vcodec ppm - 2>/dev/null | \
        ffmpeg -ss 00:00:01 -i "$FILE_PATH" -vframes 1 -q:v 2 -f image2pipe - 2>/dev/null | \
        chafa -f sixel -s "${PV_WIDTH}x${PV_HEIGHT}" --animate off --polite on
        ;;
    application/pdf)
        # Extract first 10 pages of text
        pdftotext -l 10 "$FILE_PATH" -
        ;;
    application/zip|application/x-tar|application/x-gzip|application/x-bzip2|application/x-7z-compressed|application/x-rar)
        # List archive contents
        atool --list "$FILE_PATH"
        ;;
    text/*)
        # Use bat for syntax highlighting
        bat --color=always --style=plain --line-range "1:100" "$FILE_PATH"
        ;;
    application/json)
        jq --color-output . "$FILE_PATH" 2>/dev/null || bat --color=always --style=plain "$FILE_PATH"
        ;;
    *)
        # Fallback to basic file info or cat
        if [ -f "$FILE_PATH" ]; then
            file -b "$FILE_PATH"
        fi
        ;;
esac
