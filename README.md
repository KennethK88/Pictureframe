# Pictureframe


## Project Goal

The goal of this project is to develop a Raspberry Pi-based digital picture frame for automated image and video playback on a connected display.

The project focuses on embedded Linux development, combining C++ applications, scripting, Linux system services, and MQTT communication into an integrated software system. Additional aspects include automated media management, hardware control, and integration with Home Assistant.


## Key Features

- Automated image and video playback
- Cloud-based media synchronization
- Optional background audio playback and control
- MQTT-based remote control via Home Assistant
- Temperature-dependent fan control using a dedicated C++ application
- Automated service management and deployment


## Current Status

The Pictureframe is operational and in regular use on Raspberry Pi hardware. Media playback, Home Assistant integration, background audio control, and temperature-dependent fan control are implemented and functional.

Further development and known limitations are documented in the [Project Overview](docs/ProjectOverview.md) and [GitHub Issues](https://github.com/KennethK88/Pictureframe/issues).


## Technologies

- Embedded Linux / Raspberry Pi
- C++ / Python / Bash / Lua
- MQTT / Home Assistant
- systemd
- Make


## Documentation

- [Project Overview](docs/ProjectOverview.md)
- System Architecture: [Diagram](docs/SystemArchitecture.svg) | [PlantUML Source](docs/SystemArchitecture.puml)
- Playback Sequence Diagram: [Diagram](docs/PlaybackSequenceDiagram.svg) | [PlantUML Source](docs/PlaybackSequenceDiagram.puml)
- [Wiring](docs/Wiring.md)
- [Hardware Enclosure](hardware/enclosure/)
- [Git Conventions](docs/GitConventions.md)