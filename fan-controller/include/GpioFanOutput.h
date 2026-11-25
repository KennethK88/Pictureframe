#pragma once

#include "Types.h"

#include <gpiod.hpp>
#include <optional>

/**
 * @file GpioFanOutput.h
 * @brief Defines the GPIO output driver for the cooling fan.
 */

/**
 * @brief Controls the cooling fan through a Raspberry Pi GPIO pin.
 *
 * Uses libgpiod to manage the GPIO output and translates
 * application-specific fan states into GPIO levels.
 */
class GpioFanOutput
{
    private:
        GpioPin gpioPin;
        GpioLevel gpioLevel = GpioLevel::Low;
        std::optional<gpiod::line_request> lineRequest;

    public:

        /**
         * @brief Constructs a GPIO fan output driver.
         *
         * @param gpioPin GPIO pin used to control the cooling fan.
         */
        explicit GpioFanOutput(GpioPin gpioPin) : gpioPin(gpioPin) {}

        GpioFanOutput(const GpioFanOutput&) = delete;
        GpioFanOutput& operator=(const GpioFanOutput&) = delete;
        GpioFanOutput(GpioFanOutput&&) = delete;
        GpioFanOutput& operator=(GpioFanOutput&&) = delete;

        /**
         * @brief Destroys the GPIO fan output driver.
         */
        ~GpioFanOutput() noexcept;

        /**
         * @brief Initializes the GPIO output for fan control.
         *
         * @return true if initialization succeeds, false otherwise.
         */
        bool init();

        /**
         * @brief Sets the GPIO output according to the requested fan state.
         *
         * @param fanState Fan state to apply.
         * @return true if the operation succeeds, false otherwise.
         */
        bool setState(FanState fanState);
};