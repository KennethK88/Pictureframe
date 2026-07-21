#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

mkdir -p "$PLAYLIST_DIR"

is_video_file() {
    local file="${1,,}"

    case "$file" in
        *.mp4|*.mov)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_image_file() {
    local file="${1,,}"

    case "$file" in
        *.jpg|*.jpeg|*.png)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$CACHE_DIR/$without_extension.mp4"
}

get_image_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$IMAGE_CACHE_DIR/$without_extension.jpg"
}

: > "$PLAYLIST_FILE"

find "$MEDIA_DIR" -type f \( \
  -iname "*.jpg" -o \
  -iname "*.jpeg" -o \
  -iname "*.png" -o \
  -iname "*.mp4" -o \
  -iname "*.mov" \
\) -print0 \
| while IFS= read -r -d '' file; do
    if is_video_file "$file"; then
        cache_file="$(get_cache_file_path "$file")"

        if [ -f "$cache_file" ]; then
            echo "$cache_file" >> "$PLAYLIST_FILE"
        else
            echo "$file" >> "$PLAYLIST_FILE"
        fi
    elif is_image_file "$file"; then
        cache_file="$(get_image_cache_file_path "$file")"

        if [ -f "$cache_file" ]; then
            echo "$cache_file" >> "$PLAYLIST_FILE"
        else
            echo "$file" >> "$PLAYLIST_FILE"
        fi
    else
        echo "$file" >> "$PLAYLIST_FILE"
    fi
done

echo "Playlist created: $PLAYLIST_FILE"
echo "Media files found: $(wc -l < "$PLAYLIST_FILE")"