#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

mkdir -p "$CACHE_DIR" "$IMAGE_CACHE_DIR"

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

get_image_cache_file_path() {
    local file="$1"
    local relative="${file#$MEDIA_DIR/}"
    local without_extension="${relative%.*}"

    echo "$IMAGE_CACHE_DIR/$without_extension.jpg"
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

prepare_high_res_image() {
    local file="$1"
    local image_info
    local width
    local height
    local pixels
    local output
    local output_dir
    local temp_output

    image_info="$("$PICTUREFRAME_HOME/scripts/image-info.py" "$file" 2>/dev/null || true)"

    if [ -z "$image_info" ]; then
        echo "Skipping unreadable image: $file"
        return 0
    fi

    IFS=';' read -r width height pixels <<< "$image_info"

    if [ "$pixels" -le "$HIGH_RES_IMAGE_PIXEL_THRESHOLD" ]; then
        return 0
    fi

    output="$(get_image_cache_file_path "$file")"
    output_dir="$(dirname "$output")"
    temp_output="${output}.tmp.jpg"

    mkdir -p "$output_dir"

    if [ -f "$output" ] && [ "$output" -nt "$file" ]; then
        echo "Optimized image already exists: $output"
        return 0
    fi

    echo "Optimizing high-resolution image:"
    echo "  Source:     $file"
    echo "  Resolution: ${width}x${height}"
    echo "  Pixels:     $pixels"
    echo "  Target:     $output"

    if vipsthumbnail "$file" \
        --size 1920x1080 \
        --rotate \
        --output "${temp_output}[Q=85,strip]"; then

        mv "$temp_output" "$output"
    else
        echo "Failed to optimize image: $file"
        rm -f "$temp_output"
        return 0
    fi
}

prepare_media_file() {
    local file="$1"
    local force="${2:-0}"
    local rotation

    if [ ! -f "$file" ]; then
        echo "Skipping missing file: $file"
        return 0
    fi

    if is_video_file "$file"; then
        if [ "$force" = "1" ]; then
            rm -f "$(get_cache_file_path "$file")"
        fi

        rotation="$(get_video_rotation "$file" || true)"
        rotation="${rotation%%.*}"

        case "$rotation" in
            -90|90|180|-180)
                prepare_rotated_video "$file" "$rotation"
                ;;
        esac

    elif is_image_file "$file"; then
        if [ "$force" = "1" ]; then
            rm -f "$(get_image_cache_file_path "$file")"
        fi

        prepare_high_res_image "$file"
    fi
}

prepare_media_from_list() {
    local list_file="$1"

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        prepare_media_file "$file" 1
    done < "$list_file"
}

prepare_all_media() {
    find "$MEDIA_DIR" -type f \( \
        -iname "*.mp4" -o \
        -iname "*.mov" -o \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" \
    \) -print0 \
    | while IFS= read -r -d '' file; do
        prepare_media_file "$file" 0
    done
}

echo "Preparing media..."

if [ "$#" -gt 0 ]; then
    echo "Preparing changed media from list: $1"
    prepare_media_from_list "$1"
else
    echo "No media list supplied. Preparing all media."
    prepare_all_media
fi

echo "Media preparation finished."