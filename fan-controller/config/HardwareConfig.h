#pragma once

#include "Types.h"

/**
 * @file HardwareConfig.h
 * @brief Defines hardware-specific configuration parameters for the fan controller.
 */

/**
 * @brief Contains hardware configuration constants for the fan controller.
 */
namespace HardwareConfig
{
    /**
     * @brief GPIO pin used to control the cooling fan.
     */
    constexpr GpioPin FAN_DIGITAL_PIN = 18;
}