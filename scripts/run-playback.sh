#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

wait_for_hdmi()
{
    echo "Waiting for HDMI connection..."

    local last_status=""

    while true; do
        for status_file in /sys/class/drm/card*-HDMI-A-*/status; do
            [ -e "$status_file" ] || continue

            local status
            status=$(cat "$status_file")

            if [ "$status" != "$last_status" ]; then
                echo "HDMI status: $status_file = $status"
                last_status="$status"
            fi

            if [ "$status" = "connected" ]; then
                echo "HDMI connected. Waiting briefly for DRM to settle..."
                sleep 3
                return 0
            fi
        done

        sleep 2
    done
}

echo "Preparing pictureframe playback..."

"$PICTUREFRAME_HOME/scripts/sync-media.sh"

if [ -s "$CHANGED_MEDIA_FILE" ]; then
    "$PICTUREFRAME_HOME/scripts/prepare-media.sh" "$CHANGED_MEDIA_FILE"
else
    echo "No new or changed media. Skipping media preparation."
fi

"$PICTUREFRAME_HOME/scripts/create-playlist.sh"

MEDIA_COUNT=$(wc -l < "$PLAYLIST_FILE")

if [ "$MEDIA_COUNT" -eq 0 ]; then
    echo "No media files found in playlist."
    exit 1
fi

echo "Trying to wake TV via CEC..."
timeout 3s sh -c 'echo "as" | cec-client -s -d 1 -t p' >/dev/null 2>&1 || true

wait_for_hdmi

echo "Starting pictureframe playback..."
echo "Playlist: $PLAYLIST_FILE"
echo "Media files: $MEDIA_COUNT"
echo "Image duration: ${MPV_IMAGE_DURATION_SECONDS}s"

exec mpv \
  --vo=gpu \
  --gpu-context=drm \
  --fs \
  --shuffle \
  --loop-playlist=inf \
  --hwdec=v4l2m2m \
  --drm-drmprime-video-plane=primary \
  --drm-draw-plane=overlay \
  --audio-device='alsa/hdmi:CARD=vc4hdmi,DEV=0' \
  --image-display-duration="$MPV_IMAGE_DURATION_SECONDS" \
  --vf="lavfi=[scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,format=yuv420p]" \
  --script="$PICTUREFRAME_HOME/scripts/location-overlay.lua" \
  --script-opts="location_overlay-image_duration=$MPV_IMAGE_DURATION_SECONDS,location_overlay-display_duration=5" \
  --osd-align-x=right \
  --osd-align-y=top \
  --osd-font-size=42 \
  --osd-margin-x=60 \
  --osd-margin-y=60 \
  --term-playing-msg='NOW PLAYING: ${path}' \
  --playlist="$PLAYLIST_FILE"
