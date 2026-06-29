#!/bin/sh
# lf previewer script

FILE_PATH="$1"
PV_WIDTH="$2"
PV_HEIGHT="$3"

# Cache configuration
CACHE_DIR="$HOME/.cache/lf-thumbnails"
mkdir -p "$CACHE_DIR"

MIME=$(file --mime-type -Lb "$FILE_PATH")

get_cache() {
    # Key: hash of path and modification time
    FILE_HASH=$(printf "%s:%s" "$1" "$(stat -c %Y "$1")" | xxhsum | cut -d' ' -f1)
    CACHE_FILE="$CACHE_DIR/$FILE_HASH"
    echo $CACHE_FILE
}

render_preview() {
    chafa -f sixel -s "${PV_WIDTH}x${PV_HEIGHT}" --animate off --polite on "$1"
}

case "$MIME" in
    image/*)
        # Use chafa for Sixel image previews
        render_preview "$FILE_PATH"
        ;;
    video/*)
        # Generate thumbnail if missing or stale
        CACHE_FILE=$(get_cache $FILE_PATH)
        if [ ! -f "$CACHE_FILE.jpg" ]; then
            ffmpegthumbnailer -i "$FILE_PATH" -o "$CACHE_FILE.jpg" -s 0 -q 10 -t 10% 2>/dev/null
        fi
        # Render cached image with chafa
        render_preview "$CACHE_FILE.jpg"
        ;;
    application/pdf)
        # Generate thumbnail if missing or stale
        CACHE_FILE=$(get_cache $FILE_PATH)
        if [ ! -f "$CACHE_FILE.jpg" ]; then
            # Create image preview from the first page
            pdftoppm -f 1 -l 1 -scale-to-x 1920 -scale-to-y -1 -singlefile -jpeg -tiffcompression jpeg "$FILE_PATH" "$CACHE_FILE"
        fi
        # Render cached image with chafa
        render_preview "$CACHE_FILE.jpg"
        ;;
    application/zip|application/gzip|application/x-7z-compressed|application/vnd.rar)
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
