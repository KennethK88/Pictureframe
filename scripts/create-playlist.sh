#!/bin/bash

#
# Creates a media playlist for the Pictureframe.
#
# Recursively discovers supported image and video files in the media
# directory and writes their paths to the configured playlist file.
#
# Prefers optimized media files from the corresponding cache directories
# when available. Otherwise, the original media files are used.
#
# Configuration:
#   $HOME/pictureframe/config/pictureframe.env
#

set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

mkdir -p "$PLAYLIST_DIR"

# Checks whether the given file has a supported video extension.
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

# Checks whether the given file has a supported image extension.
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

# Determines the expected cache path for an optimized video file.
# Preserves the relative directory structure and uses the MP4 extension.
get_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$CACHE_DIR/$without_extension.mp4"
}

# Determines the expected cache path for an optimized image file.
# Preserves the relative directory structure and uses the JPEG extension.
get_image_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$IMAGE_CACHE_DIR/$without_extension.jpg"
}

# Rebuild the playlist using cached media when available.
# Fall back to the original files if no optimized version exists.
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