#pragma once

/**
 * @file Types.h
 * @brief Defines common data types used by the fan controller.
 */

/**
 * @brief Represents a temperature value used by the fan controller.
 */
using Temperature = double;

/**
 * @brief Represents the operating state of the cooling fan.
 */
enum class FanState
{
    Off,
    On
};

/**
 * @brief Represents the logical level of a GPIO pin.
 */
enum class GpioLevel
{
    Low,
    High
};

/**
 * @brief Identifies a GPIO pin.
 */
using GpioPin = unsigned int;