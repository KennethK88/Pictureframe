# Project Overview: Pictureframe

## Project Goal

The goal of this project is to develop a Raspberry Pi-based digital picture frame for automated image and video playback on a connected display.

The system combines media synchronization and processing, playback control, MQTT communication, and temperature-dependent hardware control.

The project focuses on embedded Linux development, integrating C++ applications, scripting, Linux system services, and external components into a maintainable software system.


## Current Status

The Pictureframe is operational and in regular use.

Media playback, cloud synchronization, Home Assistant integration, background audio control, and temperature-dependent fan control are implemented and functional.

A custom Linux image based on Buildroot is currently under development to provide a tailored operating system for the Pictureframe.

### Media Management and Playback

Media files are synchronized from OneDrive and prepared for playback.

High-resolution images and videos are optimized when necessary. Processed media files are cached to avoid repeated processing.

Playback is handled by mpv and supports continuous, shuffled image and video playback with an optional location overlay.

### Background Audio

Optional background audio playback is coordinated with the currently displayed media.

Background audio can be played during image playback and is automatically stopped during video playback or when media playback ends.

Background audio can also be enabled or disabled through Home Assistant.

### Communication and Remote Control

The Pictureframe communicates with Home Assistant via MQTT using a Mosquitto broker.

Remote control functionality includes starting media playback, controlling background audio, and shutting down the Raspberry Pi.

### Fan Control

A dedicated C++ application monitors the Raspberry Pi CPU temperature and controls a cooling fan.

Temperature thresholds with hysteresis are used to prevent unnecessary switching.

### Supported Hardware

The system currently runs on a Raspberry Pi 3 Model A+ connected to a display via HDMI.

A custom enclosure has been developed to integrate the hardware into the VESA mounting interface of the display.

The enclosure design and related files are documented in [hardware/enclosure](../hardware/enclosure/).


## Software Architecture

The Pictureframe follows a service-oriented architecture based on three independent Linux system services managed by systemd.

The separation of responsibilities allows media playback, remote control, and hardware management to operate independently.

### Playback Service

The `pictureframe-playback.service` coordinates media synchronization, preparation, playlist generation, and playback.

Bash scripts manage the playback workflow, Python provides image metadata inspection, and Lua scripts extend mpv with additional functionality.

### MQTT Control Service

The `pictureframe-mqtt-control.service` handles communication with the MQTT broker.

A Bash-based controller receives MQTT commands and translates them into system operations, including systemd service control and background audio management.

### Fan Controller Service

The `pictureframe-fan-controller.service` runs a dedicated C++ application for temperature-dependent fan control.

The application separates control logic from hardware-specific functionality.

### Deployment

Deployment and system service installation are automated through a Makefile.

Additional architecture details are documented using UML diagrams.


## Functional Scope

### Media Management and Playback

- [x] Synchronize media files from cloud storage
- [x] Prepare high-resolution images for playback
- [x] Optimize video files for playback
- [x] Cache processed media files
- [x] Generate media playlists
- [x] Implement automated image and video playback
- [x] Display location information during playback
- [x] Implement optional background audio playback
- [x] Coordinate background audio with image and video playback

### Communication and System Management

- [x] Implement MQTT-based remote control
- [x] Integrate remote control into Home Assistant
- [x] Support remote playback start
- [x] Support remote background audio control
- [x] Support remote system shutdown
- [x] Manage application components through systemd
- [x] Implement automated deployment and service installation

### Hardware Control

- [x] Implement CPU temperature monitoring
- [x] Implement temperature-dependent fan control
- [x] Implement switching hysteresis
- [x] Integrate the fan controller as an independent system service

## Required Hardware

- [x] Raspberry Pi
- [x] HDMI display
- [x] Cooling fan
- [x] Fan switching circuitry
- [x] Custom enclosure with VESA mounting


## Test Strategy

### Manual System Tests

- Verify media synchronization from cloud storage
- Verify image and video preparation
- Verify continuous image and video playback
- Verify location overlay functionality
- Verify background audio transitions between images and videos
- Verify MQTT communication and Home Assistant integration
- Verify remote playback start and background audio control
- Verify systemd service startup, shutdown, and restart behavior
- Verify CPU temperature monitoring and fan switching

Automated testing of the C++ fan controller and CI integration are planned and tracked in [GitHub Issues](https://github.com/KennethK88/Pictureframe/issues).