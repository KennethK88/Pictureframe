#!/bin/bash

#
# Displays diagnostic information about the Pictureframe.
#
# Reports whether mpv is running, the current playlist and media count,
# and the most recent mpv log file, if available.
#
# Also displays the configured media directory and OneDrive source.
#
# Configuration:
#   $HOME/pictureframe/config/pictureframe.env
#

set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

echo "Pictureframe status"
echo "-------------------"

if pgrep -x mpv > /dev/null; then
    echo "Playback: running"
    pgrep -a mpv
else
    echo "Playback: not running"
fi

echo

if [ -f "$PLAYLIST_FILE" ]; then
    echo "Playlist: $PLAYLIST_FILE"
    echo "Media files: $(wc -l < "$PLAYLIST_FILE")"
else
    echo "Playlist: not found"
fi

echo

if ls "$LOG_DIR"/mpv-*.log > /dev/null 2>&1; then
    LATEST_LOG=$(ls -t "$LOG_DIR"/mpv-*.log | head -n 1)
    echo "Latest mpv log: $LATEST_LOG"
else
    echo "Latest mpv log: none"
fi

echo

echo "Media directory: $MEDIA_DIR"
echo "OneDrive source: $ONEDRIVE_REMOTE"
