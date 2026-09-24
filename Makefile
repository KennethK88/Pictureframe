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
SERVICE_NAME_FAN = pictureframe-fan-controller.service

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic \
           -Ifan-controller/include \
           -Ifan-controller/common \
		   -Ifan-controller/config

LDLIBS = -lgpiodcxx -lgpiod

FAN_CONTROLLER_TARGET = fan-controller/build/pictureframe-fan-controller
FAN_CONTROLLER_DIR = fan-controller

.PHONY: ping ssh-test status log live-log stop-playback stop-mqtt stop-all stop-fan start-playback start-mqtt start-fan start-all restart-playback restart-mqtt restart-fan restart-all deploy-configs deploy-scripts deploy-services deploy-audio deploy-all install-fan-service install-services temp off reboot throttled deploy-fan-controller build-fan-controller

ping:
	ping -c 1 $(PI_HOST)

ssh-test:
	$(SSH) "hostname && pwd"

status:
	$(SSH) systemctl --no-pager status $(SERVICE_NAME_PLAYBACK) || true
	$(SSH) systemctl --no-pager status $(SERVICE_NAME_MQTT) || true 
	$(SSH) systemctl --no-pager status $(SERVICE_NAME_FAN) || true

log:
	$(SSH) "journalctl --no-pager -u $(SERVICE_NAME_PLAYBACK) -n 30"

live-log:
	$(SSH) "journalctl -u $(SERVICE_NAME_PLAYBACK) -f"

stop-playback:
	$(SSH) sudo systemctl stop $(SERVICE_NAME_PLAYBACK)

stop-mqtt:
	$(SSH) sudo systemctl stop $(SERVICE_NAME_MQTT)

stop-fan:
	$(SSH) sudo systemctl stop $(SERVICE_NAME_FAN)

stop-all: stop-playback stop-mqtt stop-fan

start-playback:
	$(SSH) sudo systemctl start $(SERVICE_NAME_PLAYBACK)

start-mqtt:
	$(SSH) sudo systemctl start $(SERVICE_NAME_MQTT)

start-fan:
	$(SSH) sudo systemctl start $(SERVICE_NAME_FAN)

start-all: start-playback start-mqtt start-fan

restart-playback:
	$(SSH) sudo systemctl restart $(SERVICE_NAME_PLAYBACK)

restart-mqtt:
	$(SSH) sudo systemctl restart $(SERVICE_NAME_MQTT)

restart-fan:
	$(SSH) sudo systemctl restart $(SERVICE_NAME_FAN)

restart-all: restart-playback restart-mqtt restart-fan

deploy-configs:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/config"
	$(RSYNC) $(CONFIG_FILES) $(REMOTE)/config/

deploy-scripts:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/scripts"
	$(RSYNC) --delete scripts/ $(REMOTE)/scripts/

deploy-services:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/systemd"
	$(RSYNC) --delete systemd/ $(REMOTE)/systemd/

deploy-audio:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/audio"
	$(RSYNC) --delete audio/ $(REMOTE)/audio/

deploy-all: deploy-configs deploy-scripts deploy-audio deploy-services

install-fan-service: deploy-services
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_FAN) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_FAN)"
	$(SSH) "sudo systemctl daemon-reload"

install-services: deploy-services
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_PLAYBACK) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_PLAYBACK)"
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_MQTT) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_MQTT)"
	$(SSH) "sudo install -m 644 $(PI_TARGET_DIR)/systemd/$(SERVICE_NAME_FAN) $(PI_SERVICE_TARGET_DIR)/$(SERVICE_NAME_FAN)"
	$(SSH) "sudo systemctl daemon-reload"

temp:
	$(SSH) "vcgencmd measure_temp"

off: stop-playback
	$(SSH) "sync && sudo poweroff"

reboot: stop-playback
	$(SSH) "sync && sudo reboot"

throttled:
	$(SSH) "vcgencmd get_throttled"

deploy-fan-controller:
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/$(FAN_CONTROLLER_DIR)"
	$(RSYNC) --delete $(FAN_CONTROLLER_DIR)/ $(REMOTE)/$(FAN_CONTROLLER_DIR)/

build-fan-controller: deploy-fan-controller
	$(SSH) "mkdir -p $(PI_TARGET_DIR)/$(FAN_CONTROLLER_DIR)/build && \
	cd $(PI_TARGET_DIR) && \
	$(CXX) $(CXXFLAGS) \
	$(FAN_CONTROLLER_DIR)/src/main.cpp \
	$(FAN_CONTROLLER_DIR)/src/CpuTemperatureReader.cpp \
	$(FAN_CONTROLLER_DIR)/src/FanController.cpp \
	$(FAN_CONTROLLER_DIR)/src/GpioFanOutput.cpp \
	-o $(FAN_CONTROLLER_TARGET) \
	$(LDLIBS)"