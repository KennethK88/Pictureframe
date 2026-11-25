#!/bin/bash

#
# Synchronizes Pictureframe media files from OneDrive using rclone.
#
# Copies new and modified files to the local media directory.
# Identifies new and changed image and video files and writes their
# absolute paths to a change list for subsequent media preparation.
#
# Uses rclone copy to preserve local files that no longer exist
# in the cloud source.
#
# Configuration:
#   $HOME/pictureframe/config/pictureframe.env
#
# Dependencies:
#   rclone
#

set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

SYNC_CACHE_DIR="$PICTUREFRAME_HOME/cache/sync"
MISSING_ON_DST_FILE="$SYNC_CACHE_DIR/missing-on-dst.txt"
DIFFER_FILE="$SYNC_CACHE_DIR/differ.txt"

mkdir -p "$MEDIA_DIR" "$LOG_DIR" "$SYNC_CACHE_DIR" "$(dirname "$CHANGED_MEDIA_FILE")"

: > "$CHANGED_MEDIA_FILE"
: > "$MISSING_ON_DST_FILE"
: > "$DIFFER_FILE"

echo "Starting media sync..."
echo "Source: $ONEDRIVE_REMOTE"
echo "Target: $MEDIA_DIR"

# Synchronize media files and record missing or differing destination files.
# These lists are used to identify media requiring further processing.
rclone copy "$ONEDRIVE_REMOTE" "$MEDIA_DIR" -P \
    --missing-on-dst "$MISSING_ON_DST_FILE" \
    --differ "$DIFFER_FILE"

# Combine and deduplicate the detected changes.
# Include only supported image and video formats in the change list.
cat "$MISSING_ON_DST_FILE" "$DIFFER_FILE" \
| sort -u \
| while IFS= read -r relative_file; do
    case "${relative_file,,}" in
        *.jpg|*.jpeg|*.png|*.mp4|*.mov)
            echo "$MEDIA_DIR/$relative_file"
            ;;
    esac
done > "$CHANGED_MEDIA_FILE"

echo "Media sync finished."
echo "Changed media files: $(wc -l < "$CHANGED_MEDIA_FILE")"