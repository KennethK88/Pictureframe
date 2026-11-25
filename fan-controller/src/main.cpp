#include "Types.h"
#include "CpuTemperatureReader.h"
#include "FanController.h"
#include "GpioFanOutput.h"
#include "HardwareConfig.h"

#include <iostream>
#include <optional>
#include <thread>
#include <chrono>
#include <csignal>

/**
 * @file main.cpp
 * @brief Implements the main application of the Pictureframe fan controller.
 *
 * Coordinates CPU temperature monitoring and GPIO-based fan control.
 * Handles termination signals and applies a fail-safe strategy
 * when CPU temperature readings fail.
 */

volatile std::sig_atomic_t stopRequested = 0;

void handleSignal(int)
{
    stopRequested = 1;
}

int main()
{
    std::signal(SIGINT, handleSignal);
    std::signal(SIGTERM, handleSignal);
    
    std::cout << "Pictureframe fan controller starting..." << std::endl;

    CpuTemperatureReader cpuTemperatureReader;
    FanController fanController;
    GpioFanOutput gpioFanOutput(HardwareConfig::FAN_DIGITAL_PIN);
    if (!gpioFanOutput.init()) return 1;

    while (!stopRequested)
    {
        std::optional<Temperature> cpuTemperature = cpuTemperatureReader.getTemperature();

        if (!cpuTemperature)
        {
            std::cerr << "Could not read CPU temperature!\n";
            if (!gpioFanOutput.setState(FanState::On))
            {
                std::cerr << "Failed to set fan state!\n";
                return 1;
            }
            fanController.forceState(FanState::On);
            std::this_thread::sleep_for(std::chrono::seconds(5));
            continue;
        }
        
        std::cout << "CPU temperature: " << cpuTemperature.value() << std::endl;
        FanState fanState = fanController.updateState(cpuTemperature.value());

        if (!gpioFanOutput.setState(fanState))
        {
            std::cerr << "Failed to set fan state!\n";
            return 1;
        }

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
}