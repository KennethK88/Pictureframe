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

exec env DISPLAY="$DISPLAY_ID" mpv \
  --vo=sdl \
  --fs \
  --shuffle \
  --loop-playlist=inf \
  --image-display-duration="$MPV_IMAGE_DURATION_SECONDS" \
  --vf="lavfi=[scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2]" \
  --term-playing-msg='NOW PLAYING: ${path}' \
  --playlist="$PLAYLIST_FILE"
