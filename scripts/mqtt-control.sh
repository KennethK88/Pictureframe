#!/bin/bash
set -euo pipefail

source "$HOME/pictureframe/config/mqtt-control.env"

echo "Starting pictureframe MQTT control..."
echo "Broker: $MQTT_BROKER:$MQTT_PORT"
echo "Client ID: $MQTT_CLIENT_ID"
echo "Command topic: $MQTT_COMMAND_TOPIC"

mosquitto_sub \
  -h "$MQTT_BROKER" \
  -p "$MQTT_PORT" \
  -u "$MQTT_USER" \
  -P "$MQTT_PASS" \
  -i "$MQTT_CLIENT_ID" \
  -t "$MQTT_COMMAND_TOPIC" \
| while IFS= read -r command; do
    echo "MQTT command received: $command"

    case "$command" in
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

        background_audio_on)
            echo "Enabling background audio..."
            "$HOME/pictureframe/scripts/background-audio-control.sh" enable
            ;;

        background_audio_off)
            echo "Disabling background audio..."
            "$HOME/pictureframe/scripts/background-audio-control.sh" disable
            ;;    

        *)
            echo "Ignoring unknown command: $command"
            ;;
    esac
done
