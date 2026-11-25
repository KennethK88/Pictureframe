#!/bin/bash

#
# Stops Pictureframe media playback.
#
# Checks whether an mpv process is running and terminates it if found.
# Reports whether playback was stopped or mpv was already inactive.
#

set -euo pipefail

echo "Stopping pictureframe playback..."

if pgrep -x mpv > /dev/null; then
    pkill mpv
    echo "mpv stopped."
else
    echo "mpv is not running."
fi
