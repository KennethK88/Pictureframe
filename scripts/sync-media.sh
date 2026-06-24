#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

mkdir -p "$MEDIA_DIR" "$LOG_DIR"

echo "Starting media sync..."
echo "Source: $ONEDRIVE_REMOTE"
echo "Target: $MEDIA_DIR"

rclone copy "$ONEDRIVE_REMOTE" "$MEDIA_DIR" -P

echo "Media sync finished."
