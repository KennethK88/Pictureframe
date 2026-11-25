#pragma once

#include "Types.h"

#include <optional>

/**
 * @file CpuTemperatureReader.h
 * @brief Defines the reader for the Raspberry Pi CPU temperature.
 */

/**
 * @brief Reads the current CPU temperature of the Raspberry Pi.
 */
class CpuTemperatureReader
{
    public:
        /**
         * @brief Reads the current CPU temperature.
         *
         * @return CPU temperature in degrees Celsius if reading succeeds,
         *         std::nullopt otherwise.
         */
        std::optional<Temperature> getTemperature() const;
};