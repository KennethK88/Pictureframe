#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

mkdir -p "$CACHE_DIR"

SCALE_FILTER="scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"

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

get_video_rotation() {
    local file="$1"

    ffprobe -v error \
        -select_streams v:0 \
        -show_entries stream_tags=rotate:stream_side_data=rotation \
        -of default=nw=1 \
        "$file" 2>/dev/null \
        | sed -nE 's/^(rotation|TAG:rotate)=(-?[0-9.]+).*/\2/p' \
        | head -n 1
}

get_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$CACHE_DIR/$without_extension.mp4"
}

prepare_rotated_video() {
    local file="$1"
    local rotation="$2"
    local output
    local output_dir
    local filter

    output="$(get_cache_file_path "$file")"
    output_dir="$(dirname "$output")"

    mkdir -p "$output_dir"

    if [ -f "$output" ] && [ "$output" -nt "$file" ]; then
        echo "Optimized video already exists: $output"
        return 0
    fi

    case "$rotation" in
        -90)
            filter="transpose=clock,$SCALE_FILTER"
            ;;
        90)
            filter="transpose=cclock,$SCALE_FILTER"
            ;;
        180|-180)
            filter="transpose=clock,transpose=clock,$SCALE_FILTER"
            ;;
        *)
            return 0
            ;;
    esac

    echo "Optimizing rotated video:"
    echo "  Source:   $file"
    echo "  Rotation: $rotation"
    echo "  Target:   $output"

    ffmpeg -nostdin -y \
   	 -noautorotate \
   	 -display_rotation 0 \
   	 -i "$file" \
   	 -map 0:v:0 \
   	 -map 0:a? \
   	 -dn \
   	 -vf "$filter" \
   	 -c:v libx264 \
   	 -preset veryfast \
   	 -crf 21 \
   	 -pix_fmt yuv420p \
   	 -c:a copy \
   	 -movflags +faststart \
   	 -map_metadata -1 \
   	 -metadata:s:v:0 rotate=0 \
   	 "$output"
}

echo "Preparing media..."

find "$MEDIA_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 \
| while IFS= read -r -d '' file; do
    rotation="$(get_video_rotation "$file" || true)"
    rotation="${rotation%%.*}"

    case "$rotation" in
        -90|90|180|-180)
            prepare_rotated_video "$file" "$rotation"
            ;;
    esac
done

echo "Media preparation finished."
