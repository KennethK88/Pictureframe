#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

echo "Preparing pictureframe playback..."

"$PICTUREFRAME_HOME/scripts/sync-media.sh"
"$PICTUREFRAME_HOME/scripts/prepare-media.sh"
"$PICTUREFRAME_HOME/scripts/create-playlist.sh"

MEDIA_COUNT=$(wc -l < "$PLAYLIST_FILE")

if [ "$MEDIA_COUNT" -eq 0 ]; then
    echo "No media files found in playlist."
    exit 1
fi

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
  --term-playing-msg='NOW PLAYING: ${path}' \
  --playlist="$PLAYLIST_FILE"
