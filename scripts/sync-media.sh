#!/bin/bash
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

rclone copy "$ONEDRIVE_REMOTE" "$MEDIA_DIR" -P \
    --missing-on-dst "$MISSING_ON_DST_FILE" \
    --differ "$DIFFER_FILE"

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