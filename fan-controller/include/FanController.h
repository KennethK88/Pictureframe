#pragma once

#include "Types.h"

/**
 * @file FanController.h
 * @brief Defines the temperature-dependent fan controller.
 */

/**
 * @brief Controls the fan state based on the Raspberry Pi CPU temperature.
 *
 * Uses temperature thresholds with hysteresis to prevent frequent
 * switching between the on and off states.
 */
class FanController
{
    private:
        FanState fanState = FanState::Off;

    public:

        /**
         * @brief Updates the fan state based on the current CPU temperature.
         *
         * Applies temperature thresholds with hysteresis to determine
         * whether the fan should be switched on or off.
         *
         * @param cpuTemperature Current CPU temperature in degrees Celsius.
         * @return Updated fan state.
         */
        FanState updateState(Temperature cpuTemperature);

        /**
         * @brief Explicitly sets the fan state.
         *
         * @param forcedFanState Fan state to apply.
         */
        void forceState(FanState forcedFanState);
};