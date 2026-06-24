#!/bin/bash
set -euo pipefail

echo "Stopping pictureframe playback..."

if pgrep -x mpv > /dev/null; then
    pkill mpv
    echo "mpv stopped."
else
    echo "mpv is not running."
fi
