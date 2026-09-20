#pragma once
#include <gpiod.hpp>
#include <optional>
#include "Types.h"

class GpioFanOutput
{
    private:
        GpioPin gpioPin;
        GpioLevel gpioLevel = GpioLevel::Low;
        std::optional<gpiod::line_request> lineRequest;

    public:
        explicit GpioFanOutput(GpioPin gpioPin) : gpioPin(gpioPin) {}
        GpioFanOutput(const GpioFanOutput&) = delete;
        GpioFanOutput& operator=(const GpioFanOutput&) = delete;
        GpioFanOutput(GpioFanOutput&&) = delete;
        GpioFanOutput& operator=(GpioFanOutput&&) = delete;
        ~GpioFanOutput() noexcept;
        bool init();
        bool setState(FanState fanState);
};