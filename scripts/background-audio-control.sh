#!/bin/bash

#
# Controls optional background audio playback for the Pictureframe.
#
# Manages a separate mpv audio player based on the current media type
# and the user's background audio preference.
#
# Background audio is played only when enabled and an image is displayed.
# Playback is stopped during video playback or when the media player is idle.
#
# Configuration:
#   $HOME/pictureframe/config/pictureframe.env
#
# Commands:
#   enable, disable, image, video, idle, sync, status
#

set -euo pipefail

source "$HOME/pictureframe/config/pictureframe.env"

STATE_DIR="/tmp/pictureframe-background-audio"
ENABLED_FILE="$STATE_DIR/enabled"
MEDIA_FILE="$STATE_DIR/media"
PID_FILE="$STATE_DIR/player.pid"

umask 077
mkdir -p "$STATE_DIR"

# Initializes persistent runtime state files with their default values
# if they do not already exist.
initialize_state()
{
    if [ ! -f "$ENABLED_FILE" ]; then
        case "$BACKGROUND_AUDIO_ENABLED_DEFAULT" in
            true|false)
                printf '%s\n' "$BACKGROUND_AUDIO_ENABLED_DEFAULT" > "$ENABLED_FILE"
                ;;
            *)
                echo "Invalid BACKGROUND_AUDIO_ENABLED_DEFAULT: $BACKGROUND_AUDIO_ENABLED_DEFAULT" >&2
                exit 1
                ;;
        esac
    fi

    if [ ! -f "$MEDIA_FILE" ]; then
        printf '%s\n' "idle" > "$MEDIA_FILE"
    fi
}

# Checks whether the background audio player is still running.
# Validates the stored PID and verifies that it belongs to the expected
# mpv process. Removes stale PID files when necessary.
is_player_running()
{
    [ -s "$PID_FILE" ] || return 1

    local pid
    pid=$(cat "$PID_FILE")

    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        rm -f "$PID_FILE"
        return 1
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$PID_FILE"
        return 1
    fi

    if [ -r "/proc/$pid/cmdline" ]; then
        local cmdline
        cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline")

        if [[ "$cmdline" != *"mpv"* ]] ||
           [[ "$cmdline" != *"$BACKGROUND_AUDIO_FILE"* ]]; then
            rm -f "$PID_FILE"
            return 1
        fi
    fi

    PLAYER_PID="$pid"
    return 0
}

# Starts background audio playback using mpv.
# Does nothing if the expected player process is already running.
start_player()
{
    if is_player_running; then
        return 0
    fi

    if [ ! -f "$BACKGROUND_AUDIO_FILE" ]; then
        echo "Background audio file not found: $BACKGROUND_AUDIO_FILE" >&2
        return 1
    fi

    mpv \
        --no-video \
        --no-terminal \
        --really-quiet \
        --loop-file=inf \
        --gapless-audio=yes \
        --audio-device="$MPV_AUDIO_DEVICE" \
        "$BACKGROUND_AUDIO_FILE" \
        </dev/null >/dev/null 2>&1 &

    local pid=$!
    printf '%s\n' "$pid" > "$PID_FILE"

    sleep 0.1

    if ! is_player_running; then
        echo "Failed to start background audio." >&2
        return 1
    fi

    echo "Background audio started (PID $pid)."
}

# Stops the background audio player.
# Attempts graceful termination before forcibly killing the process.
stop_player()
{
    if ! is_player_running; then
        rm -f "$PID_FILE"
        return 0
    fi

    local pid="$PLAYER_PID"

    kill "$pid" 2>/dev/null || true

    for ((i = 0; i < 20; ++i)); do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi

        sleep 0.05
    done

    if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null || true
    fi

    rm -f "$PID_FILE"

    echo "Background audio stopped."
}

# Synchronizes background audio playback with the current runtime state.
# Audio is played only when enabled and the active media type is an image.
sync_player()
{
    local enabled
    local media

    enabled=$(cat "$ENABLED_FILE")
    media=$(cat "$MEDIA_FILE")

    if [ "$enabled" = "true" ] && [ "$media" = "image" ]; then
        start_player
    else
        stop_player
    fi
}

# Initialize runtime state and process the requested command.
initialize_state

command="${1:-}"

case "$command" in
    enable)
        printf '%s\n' "true" > "$ENABLED_FILE"
        echo "Background audio enabled."
        ;;

    disable)
        printf '%s\n' "false" > "$ENABLED_FILE"
        sync_player
        echo "Background audio disabled."
        ;;

    image)
        printf '%s\n' "image" > "$MEDIA_FILE"
        sync_player
        ;;

    video)
        printf '%s\n' "video" > "$MEDIA_FILE"
        sync_player
        ;;

    idle)
        printf '%s\n' "idle" > "$MEDIA_FILE"
        sync_player
        ;;

    sync)
        sync_player
        ;;

    status)
        enabled=$(cat "$ENABLED_FILE")
        media=$(cat "$MEDIA_FILE")

        if is_player_running; then
            running=true
        else
            running=false
        fi

        echo "Background audio: enabled=$enabled, media=$media, running=$running"
        ;;

    *)
        echo "Usage: $0 {enable|disable|image|video|idle|sync|status}" >&2
        exit 1
        ;;
esac