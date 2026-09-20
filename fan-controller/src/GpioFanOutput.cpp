#include "GpioFanOutput.h"
#include <iostream>

GpioFanOutput::~GpioFanOutput() noexcept
{
    try
    {
        setState(FanState::Off);
    }
    catch(const std::exception& e)
    {
        std::cerr << "Failed to switch fan off during destruction: " << e.what() << '\n';
    }
    
}

bool GpioFanOutput::init()
{
    try
    {
        gpiod::chip chip("/dev/gpiochip0");
        gpiod::line_settings lineSettings;
        lineSettings.set_direction(gpiod::line::direction::OUTPUT);
        lineSettings.set_output_value(gpiod::line::value::INACTIVE);
        gpiod::line_config lineConfig;
        lineConfig.add_line_settings(gpioPin, lineSettings);
        gpiod::request_config requestConfig;
        requestConfig.set_consumer("pictureframe-fan-controller");
        lineRequest = chip.prepare_request()
                  .set_request_config(requestConfig)
                  .set_line_config(lineConfig)
                  .do_request();
    }
    catch (const std::exception& e)
    {
        std::cerr << "GPIO initialization failed: " << e.what() << '\n';
        return false;
    }
    return true;
}

bool GpioFanOutput::setState(FanState fanState)
{
    if (!lineRequest) return false;
    try
    {
        switch (fanState)
        {
            case FanState::Off:
                lineRequest->set_value(gpioPin, gpiod::line::value::INACTIVE);
                gpioLevel = GpioLevel::Low;
                break;
            case FanState::On:
                lineRequest->set_value(gpioPin, gpiod::line::value::ACTIVE);
                gpioLevel = GpioLevel::High;
                break;
        }
        return true;
    }
    catch(const std::exception& e)
    {
        std::cerr << "Failed to set fan state: " << e.what() << '\n';
        return false;
    }
}