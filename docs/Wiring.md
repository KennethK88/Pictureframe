# Pictureframe – Wiring

This document describes the hardware connections for the temperature-controlled cooling fan of the Pictureframe. The system uses a Raspberry Pi 3 Model A+ and a 5 V cooling fan controlled through an IRLZ44N N-channel MOSFET.


## Pin Assignments

| Function | Raspberry Pi | Connection |
|----------|--------------|------------|
| Fan VCC | 5 V | Fan positive terminal |
| Fan GND | – | IRLZ44N Drain |
| MOSFET Source | GND | Raspberry Pi GND |
| MOSFET Gate | GPIO18 (physical pin 12) | Gate resistor (100–330 Ω) |
| Gate Pulldown | GND | 100 kΩ between Gate and GND |


## Fan Control

The fan is connected to the Raspberry Pi's 5 V supply and switched using an IRLZ44N MOSFET in a low-side configuration.

GPIO18 controls the MOSFET gate through a series resistor. A 100 kΩ pulldown resistor keeps the MOSFET switched off when the GPIO is not actively driven.

The fan is controlled by a dedicated C++ application based on the Raspberry Pi CPU temperature.


## General Notes

- The fan is powered from the 5 V supply, not directly from a GPIO pin.
- GPIO18 operates at 3.3 V.
- The MOSFET switches the fan's ground connection.
- The Raspberry Pi and fan share a common ground.
- The fan current and MOSFET switching characteristics must be compatible with the available power supply and GPIO drive voltage.


## Hardware References

The following official manufacturer documentation provides additional technical details, datasheets, and board schematics.

| Hardware | Documentation |
|----------|---------------|
| Raspberry Pi 3 Model A+ | [Official Product Documentation](https://www.raspberrypi.com/products/raspberry-pi-3-model-a-plus/) |
| Raspberry Pi GPIO | [GPIO Documentation & Pinout](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html) |
| IRLZ44N | [Infineon IRLZ44N Datasheet (PDF)](https://www.infineon.com/dgdl/Infineon-IRLZ44N-DataSheet-v01_01-EN.pdf?fileId=5546d462533600a40153567217c32725) |