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
        # Cache configuration
        CACHE_DIR="$HOME/.cache/lf-thumbnails"
        mkdir -p "$CACHE_DIR"
        
        # Key: hash of path and modification time
        FILE_HASH=$(printf "%s:%s" "$FILE_PATH" "$(stat -c %Y "$FILE_PATH")" | xxhsum | cut -d' ' -f1)
        CACHE_FILE="$CACHE_DIR/$FILE_HASH.jpg"

        # Generate thumbnail if missing or stale
        if [ ! -f "$CACHE_FILE" ]; then
            ffmpegthumbnailer -i "$FILE_PATH" -o "$CACHE_FILE" -s 0 -q 10 -t 10% 2>/dev/null
        fi

        # Render cached image with chafa
        chafa -f sixel -s "${PV_WIDTH}x${PV_HEIGHT}" --animate off --polite on "$CACHE_FILE"
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
