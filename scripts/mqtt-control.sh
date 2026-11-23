#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/mqtt-control.env"

echo "Starting pictureframe MQTT control..."
echo "Broker: $MQTT_BROKER:$MQTT_PORT"
echo "Client ID: $MQTT_CLIENT_ID"
echo "Command topic: $MQTT_COMMAND_TOPIC"
echo "Background audio topic: $MQTT_BACKGROUND_AUDIO_SET_TOPIC"

run_background_audio_control()
{
    runuser -u "$PI_USER" -- env HOME="$HOME" \
        "$HOME/pictureframe/scripts/background-audio-control.sh" "$1"
}

mosquitto_sub \
  -h "$MQTT_BROKER" \
  -p "$MQTT_PORT" \
  -u "$MQTT_USER" \
  -P "$MQTT_PASS" \
  -i "$MQTT_CLIENT_ID" \
  -t "$MQTT_COMMAND_TOPIC" \
  -t "$MQTT_BACKGROUND_AUDIO_SET_TOPIC" \
  -v \
| while IFS=' ' read -r topic payload; do
    echo "MQTT message received: topic=$topic payload=$payload"

    case "$topic" in
        "$MQTT_COMMAND_TOPIC")
            case "$payload" in
                start)
                    echo "Starting pictureframe playback service..."
                    systemctl start pictureframe-playback.service
                    ;;

                shutdown)
                    echo "Stopping pictureframe playback service..."
                    systemctl stop pictureframe-playback.service || true

                    echo "Syncing filesystem..."
                    sync

                    echo "Powering off..."
                    systemctl poweroff
                    ;;

                *)
                    echo "Ignoring unknown command: $payload"
                    ;;
            esac
            ;;

        "$MQTT_BACKGROUND_AUDIO_SET_TOPIC")
            case "$payload" in
                ON)
                    echo "Enabling background audio..."
                    run_background_audio_control enable
                    ;;

                OFF)
                    echo "Disabling background audio..."
                    run_background_audio_control disable
                    ;;

                *)
                    echo "Ignoring invalid background audio value: $payload"
                    ;;
            esac
            ;;
    esac
done