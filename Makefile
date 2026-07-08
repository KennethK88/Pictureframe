PI_USER = kenneth
PI_HOST = 192.168.178.94
PI_TARGET_DIR = /home/kenneth/pictureframe
PI_SERVICE_TARGET_DIR = /etc/systemd/system

CONFIG_FILES = config/mqtt-control.env config/pictureframe.env

SSH = ssh $(PI_USER)@$(PI_HOST)
REMOTE = $(PI_USER)@$(PI_HOST):$(PI_TARGET_DIR)
RSYNC = rsync -av

SERVICE_NAME_PLAYBACK = pictureframe-playback.service
SERVICE_NAME_MQTT = pictureframe-mqtt-control.service

.PHONY: ping ssh-test status log live-log stop-playback stop-mqtt stop-all start-playback start-mqtt start-all restart-playback restart-mqtt restart-all deploy-configs deploy-scripts deploy-services deploy-all install-services temp off

ping:
	ping -c 1 $(PI_HOST)

ssh-test:
	$(SSH) "hostname && pwd"

status:
	$(SSH) systemctl --no-pager status $(SERVICE_NAME_PLAYBACK) || true
	$(SSH) systemctl --no-pager status $(SERVICE_NAME_MQTT) || true 

log:
	$(SSH) "journalctl --no-pager -u $(SERVICE_NAME_PLAYBACK) -n 30"

live-log:
	$(SSH) "journalctl -u $(SERVICE_NAME_PLAYBACK) -f"

stop-playback:
	$(SSH) sudo systemctl stop $(SERVICE_NAME_PLAYBACK)

stop-mqtt:
	$(SSH) sudo systemctl stop $(SERVICE_NAME_MQTT)

stop-all: stop-playback stop-mqtt

start-playback:
	$(SSH) sudo systemctl start $(SERVICE_NAME_PLAYBACK)

start-mqtt:
	$(SSH) sudo systemctl start $(SERVICE_NAME_MQTT)

start-all: start-playback start-mqtt

restart-playback:
	$(SSH) sudo systemctl restart $(SERVICE_NAME_PLAYBACK)

restart-mqtt:
	$(SSH) sudo systemctl restart $(SERVICE_NAME_MQTT)

restart-all: restart-playback restart-mqtt

deploy-configs:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/config"
	$(RSYNC) $(CONFIG_FILES) $(REMOTE)/config/

deploy-scripts:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/scripts"
	$(RSYNC) --delete scripts/ $(REMOTE)/scripts/

deploy-services:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/systemd"
	$(RSYNC) --delete systemd/ $(REMOTE)/systemd/

deploy-all: deploy-configs deploy-scripts deploy-services

install-services: deploy-services
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_PLAYBACK) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_PLAYBACK)"
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_MQTT) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_MQTT)"
	$(SSH) "sudo systemctl daemon-reload"

temp:
	$(SSH) "vcgencmd measure_temp"

off: stop-playback
	$(SSH) "sync && sudo poweroff"